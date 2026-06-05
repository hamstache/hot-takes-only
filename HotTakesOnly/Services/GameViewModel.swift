import Foundation
import Supabase

// Single source of truth for all game state.
// The host device drives game-phase transitions; all clients react via Realtime.
@MainActor
final class GameViewModel: ObservableObject {

    // MARK: - Published state

    @Published var room: Room?
    @Published var players: [Player] = []
    @Published var submissions: [Submission] = []
    @Published var myPlayer: Player?
    @Published var errorMessage: String?
    @Published var isLoading = false

    // MARK: - Private

    private var realtimeTask: Task<Void, Never>?
    private var supabase: SupabaseClient { SupabaseService.shared.client }

    // MARK: - Computed helpers

    var currentBlackCard: String? {
        guard let room else { return nil }
        return SampleCards.black[safe: room.blackCardIndex]
    }

    // Players ordered by join time — stable judge rotation.
    private var sortedPlayers: [Player] {
        players.sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
    }

    var currentJudge: Player? {
        guard let room, !players.isEmpty else { return nil }
        return sortedPlayers[safe: room.judgeIndex % sortedPlayers.count]
    }

    var isJudge: Bool {
        guard let myPlayer, let judge = currentJudge else { return false }
        return myPlayer.id == judge.id
    }

    var myHand: [String] {
        guard let myPlayer else { return [] }
        return myPlayer.handIndices.compactMap { SampleCards.white[safe: $0] }
    }

    var hasSubmitted: Bool {
        guard let myPlayer, let room else { return false }
        return submissions.contains {
            $0.playerId == myPlayer.id && $0.roundNumber == room.currentRound
        }
    }

    var roundSubmissions: [Submission] {
        guard let room else { return [] }
        return submissions.filter { $0.roundNumber == room.currentRound }
    }

    var allNonJudgesSubmitted: Bool {
        guard let judge = currentJudge else { return false }
        let nonJudges = players.filter { $0.id != judge.id }
        let submittedIds = Set(roundSubmissions.map(\.playerId))
        return nonJudges.allSatisfy { submittedIds.contains($0.id) }
    }

    // MARK: - Room lifecycle

    func createRoom(displayName: String) async {
        await run {
            let code = self.randomCode()
            let newRoom = NewRoom(code: code, maxRounds: 5)
            let room: Room = try await self.supabase
                .from("rooms")
                .insert(newRoom)
                .select()
                .single()
                .execute()
                .value

            let newPlayer = NewPlayer(roomId: room.id, displayName: displayName, isHost: true)
            let player: Player = try await self.supabase
                .from("players")
                .insert(newPlayer)
                .select()
                .single()
                .execute()
                .value

            self.room = room
            self.players = [player]
            self.myPlayer = player
            self.subscribeToRealtime(roomId: room.id)
        }
    }

    func joinRoom(code: String, displayName: String) async {
        await run {
            let rooms: [Room] = try await self.supabase
                .from("rooms")
                .select()
                .eq("code", value: code.uppercased())
                .eq("status", value: GamePhase.waiting.rawValue)
                .execute()
                .value

            guard let room = rooms.first else {
                throw AppError.roomNotFound
            }

            let newPlayer = NewPlayer(roomId: room.id, displayName: displayName, isHost: false)
            let player: Player = try await self.supabase
                .from("players")
                .insert(newPlayer)
                .select()
                .single()
                .execute()
                .value

            let existingPlayers: [Player] = try await self.supabase
                .from("players")
                .select()
                .eq("room_id", value: room.id.uuidString)
                .execute()
                .value

            self.room = room
            self.players = existingPlayers
            self.myPlayer = player
            self.subscribeToRealtime(roomId: room.id)
        }
    }

    func leaveRoom() {
        realtimeTask?.cancel()
        realtimeTask = nil
        room = nil
        players = []
        submissions = []
        myPlayer = nil
        errorMessage = nil
    }

    // MARK: - Host actions

    func startGame() async {
        guard let room, let myPlayer, myPlayer.isHost, players.count >= 2 else { return }

        await run {
            let blackCardIndex = Int.random(in: 0..<SampleCards.black.count)
            var usedIndices = Set<Int>()

            for player in self.sortedPlayers {
                let hand = SampleCards.dealHand(excluding: usedIndices)
                usedIndices.formUnion(hand)
                try await self.supabase
                    .from("players")
                    .update(["hand_indices": hand])
                    .eq("id", value: player.id.uuidString)
                    .execute()
            }

            let startPayload: [String: AnyJSON] = [
                "status": .string(GamePhase.submitting.rawValue),
                "current_round": .integer(1),
                "judge_index": .integer(0),
                "black_card_index": .integer(blackCardIndex),
            ]
            try await self.supabase
                .from("rooms")
                .update(startPayload)
                .eq("id", value: room.id.uuidString)
                .execute()
        }
    }

    // MARK: - Player actions

    func submitCard(handIndex: Int) async {
        guard let room, let myPlayer, !isJudge, !hasSubmitted else { return }
        guard let cardIndex = myPlayer.handIndices[safe: handIndex] else { return }

        await run {
            let newSub = NewSubmission(
                roomId: room.id,
                playerId: myPlayer.id,
                roundNumber: room.currentRound,
                cardIndex: cardIndex
            )
            try await self.supabase
                .from("submissions")
                .insert(newSub)
                .execute()

            var newHand = myPlayer.handIndices
            newHand.remove(at: handIndex)
            try await self.supabase
                .from("players")
                .update(["hand_indices": newHand])
                .eq("id", value: myPlayer.id.uuidString)
                .execute()
        }
    }

    // MARK: - Judge actions

    func pickWinner(_ submission: Submission) async {
        guard let room, isJudge else { return }

        await run {
            try await self.supabase
                .from("submissions")
                .update(["is_winner": true])
                .eq("id", value: submission.id.uuidString)
                .execute()

            if let winner = self.players.first(where: { $0.id == submission.playerId }) {
                try await self.supabase
                    .from("players")
                    .update(["score": winner.score + 1])
                    .eq("id", value: winner.id.uuidString)
                    .execute()
            }

            try await self.supabase
                .from("rooms")
                .update(["status": GamePhase.roundOver.rawValue])
                .eq("id", value: room.id.uuidString)
                .execute()
        }
    }

    func advanceRound() async {
        guard let room else { return }

        await run {
            let topScore = self.players.map(\.score).max() ?? 0
            let isGameOver = topScore >= 7 || room.currentRound >= room.maxRounds

            if isGameOver {
                try await self.supabase
                    .from("rooms")
                    .update(["status": GamePhase.finished.rawValue])
                    .eq("id", value: room.id.uuidString)
                    .execute()
                return
            }

            let nextRound = room.currentRound + 1
            let nextJudgeIndex = (room.judgeIndex + 1) % max(self.players.count, 1)
            let nextBlackCard = Int.random(in: 0..<SampleCards.black.count)

            // Refill each player's hand
            var usedIndices: Set<Int> = []
            let latestPlayers: [Player] = try await self.supabase
                .from("players")
                .select()
                .eq("room_id", value: room.id.uuidString)
                .execute()
                .value

            for player in latestPlayers {
                usedIndices.formUnion(player.handIndices)
            }
            for player in latestPlayers {
                let newHand = SampleCards.refillHand(current: player.handIndices, excluding: usedIndices)
                usedIndices.formUnion(newHand)
                try await self.supabase
                    .from("players")
                    .update(["hand_indices": newHand])
                    .eq("id", value: player.id.uuidString)
                    .execute()
            }

            let advancePayload: [String: AnyJSON] = [
                "status": .string(GamePhase.submitting.rawValue),
                "current_round": .integer(nextRound),
                "judge_index": .integer(nextJudgeIndex),
                "black_card_index": .integer(nextBlackCard),
            ]
            try await self.supabase
                .from("rooms")
                .update(advancePayload)
                .eq("id", value: room.id.uuidString)
                .execute()
        }
    }

    // MARK: - Realtime

    private func subscribeToRealtime(roomId: UUID) {
        realtimeTask?.cancel()

        realtimeTask = Task { [weak self] in
            guard let self else { return }

            let channel = self.supabase.realtimeV2.channel("game:\(roomId.uuidString)")

            let roomChanges       = channel.postgresChange(AnyAction.self, schema: "public", table: "rooms")
            let playerChanges     = channel.postgresChange(AnyAction.self, schema: "public", table: "players")
            let submissionChanges = channel.postgresChange(AnyAction.self, schema: "public", table: "submissions")

            do {
                try await channel.subscribeWithError()
            } catch {
                self.errorMessage = error.localizedDescription
                return
            }

            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    for await _ in roomChanges {
                        guard !Task.isCancelled else { return }
                        await self.refreshRoom(roomId: roomId)
                    }
                }
                group.addTask {
                    for await _ in playerChanges {
                        guard !Task.isCancelled else { return }
                        await self.refreshPlayers(roomId: roomId)
                    }
                }
                group.addTask {
                    for await _ in submissionChanges {
                        guard !Task.isCancelled else { return }
                        await self.refreshSubmissions(roomId: roomId)
                    }
                }
            }
        }
    }

    // Re-fetch helpers — called on every Realtime event.
    // Simple but reliable for a prototype with ≤10 players.

    private func refreshRoom(roomId: UUID) async {
        do {
            let rooms: [Room] = try await supabase
                .from("rooms")
                .select()
                .eq("id", value: roomId.uuidString)
                .execute()
                .value
            self.room = rooms.first
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshPlayers(roomId: UUID) async {
        do {
            let updated: [Player] = try await supabase
                .from("players")
                .select()
                .eq("room_id", value: roomId.uuidString)
                .order("created_at")
                .execute()
                .value
            self.players = updated
            // Keep myPlayer in sync
            if let id = myPlayer?.id {
                self.myPlayer = updated.first(where: { $0.id == id })
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshSubmissions(roomId: UUID) async {
        guard let room else { return }
        do {
            let updated: [Submission] = try await supabase
                .from("submissions")
                .select()
                .eq("room_id", value: roomId.uuidString)
                .eq("round_number", value: room.currentRound)
                .execute()
                .value
            self.submissions = updated
            if room.status == .submitting, allNonJudgesSubmitted, myPlayer?.isHost == true {
                try await supabase
                    .from("rooms")
                    .update(["status": AnyJSON.string(GamePhase.judging.rawValue)])
                    .eq("id", value: roomId.uuidString)
                    .execute()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Utilities

    private func run(_ action: @escaping () async throws -> Void) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await action()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func randomCode() -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}

// MARK: - App errors

enum AppError: LocalizedError {
    case roomNotFound
    case roomFull

    var errorDescription: String? {
        switch self {
        case .roomNotFound: return "Room not found or game already started."
        case .roomFull:     return "Room is full."
        }
    }
}
