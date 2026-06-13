import Foundation
import LiveKit
import Combine

@MainActor
final class LiveKitService: NSObject, ObservableObject {

    @Published var isConnected = false
    @Published var isSpeaking = false
    @Published var activeSpeakerNames: Set<String> = []

    private let room = Room()

    override init() {
        super.init()
        room.add(delegate: self)
    }

    func connect(roomId: String, displayName: String) async {
        guard let token = await fetchToken(roomId: roomId, displayName: displayName) else {
            print("[LiveKit] token fetch failed")
            return
        }
        do {
            try await room.connect(SupabaseConfig.liveKitURL, token)
            isConnected = true
            // Start muted — PTT unmutes on demand
            try? await room.localParticipant.setMicrophone(enabled: false)
        } catch {
            print("[LiveKit] connect error: \(error)")
        }
    }

    func disconnect() {
        Task { await room.disconnect() }
        isConnected = false
        isSpeaking = false
        activeSpeakerNames = []
    }

    func beginSpeaking() {
        guard isConnected else { return }
        Task {
            try? await room.localParticipant.setMicrophone(enabled: true)
            isSpeaking = true
        }
    }

    func endSpeaking() {
        Task {
            try? await room.localParticipant.setMicrophone(enabled: false)
            isSpeaking = false
        }
    }

    // MARK: - Token fetch

    private func fetchToken(roomId: String, displayName: String) async -> String? {
        guard let url = URL(string: "\(SupabaseConfig.url.absoluteString)/functions/v1/livekit-token") else {
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        let body = ["roomId": roomId, "participantName": displayName]
        guard let encoded = try? JSONEncoder().encode(body) else { return nil }
        request.httpBody = encoded
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let response = try? JSONDecoder().decode(TokenResponse.self, from: data) else {
            return nil
        }
        return response.token
    }
}

// MARK: - RoomDelegate

extension LiveKitService: RoomDelegate {
    nonisolated func room(_ room: Room, participant: Participant, didUpdate speaking: Bool) {
        let name = participant.identity?.stringValue ?? ""
        Task { @MainActor in
            if speaking {
                self.activeSpeakerNames.insert(name)
            } else {
                self.activeSpeakerNames.remove(name)
            }
        }
    }
}

private struct TokenResponse: Decodable {
    let token: String
}
