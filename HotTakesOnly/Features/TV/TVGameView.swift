import SwiftUI

struct TVGameView: View {
    @EnvironmentObject var gameVM: GameViewModel
    @State private var chatStack: [QuickChatMessage] = []

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch gameVM.room?.status {
            case .none, .waiting:
                waitingRoomView
            case .finished:
                finalScoreView
            default:
                gameplayView
            }
        }
        .animation(.easeInOut(duration: 0.5), value: gameVM.room?.status)
        .onChange(of: gameVM.latestQuickChat) { _, newChat in
            guard let newChat else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                if chatStack.count >= 3 { chatStack.removeFirst() }
                chatStack.append(newChat)
            }
            let msgId = newChat.id
            Task {
                try? await Task.sleep(for: .seconds(4))
                withAnimation(.easeOut(duration: 0.35)) {
                    chatStack.removeAll { $0.id == msgId }
                }
            }
        }
    }

    // MARK: - Waiting Room

    private var waitingRoomView: some View {
        VStack(spacing: 48) {
            Spacer()

            VStack(spacing: 12) {
                Text("Hot Takes Only")
                    .font(.system(size: 48, weight: .black))
                    .foregroundStyle(.pink)
                Text("Scan the room code to join")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }

            if let code = gameVM.room?.code {
                Text(code)
                    .font(.system(size: 80, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                    .tracking(12)
                    .padding(.horizontal, 48)
                    .padding(.vertical, 24)
                    .background(.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }

            VStack(spacing: 16) {
                Text("Players joined")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))

                HStack(spacing: 16) {
                    ForEach(gameVM.players) { player in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(player.isHost ? Color.pink : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                            Text(player.displayName)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                            if player.isHost {
                                Text("HOST")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(.pink)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.pink.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: gameVM.players.count)
            }

            Spacer()

            WaveDots(color: .pink)
                .padding(.bottom, 48)
        }
    }

    // MARK: - Final Score

    private var finalScoreView: some View {
        let sorted = gameVM.players.sorted { $0.score > $1.score }
        return VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 8) {
                Text("Game Over")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
                if let winner = sorted.first {
                    Text("🏆 \(winner.displayName) wins!")
                        .font(.system(size: 52, weight: .black))
                        .foregroundStyle(.yellow)
                }
            }

            VStack(spacing: 14) {
                ForEach(Array(sorted.enumerated()), id: \.element.id) { rank, player in
                    HStack(spacing: 20) {
                        Text(rank == 0 ? "🥇" : rank == 1 ? "🥈" : rank == 2 ? "🥉" : "   ")
                            .font(.system(size: 28))
                            .frame(width: 44)
                        Text(player.displayName)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(rank == 0 ? .yellow : .white)
                        Spacer()
                        Text("\(player.score) pts")
                            .font(.system(size: 28, weight: .black, design: .monospaced))
                            .foregroundStyle(rank == 0 ? .yellow : .white.opacity(0.6))
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 18)
                    .background(rank == 0 ? Color.yellow.opacity(0.1) : Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        rank == 0 ? RoundedRectangle(cornerRadius: 14).strokeBorder(.yellow.opacity(0.3), lineWidth: 1.5) : nil
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .frame(maxWidth: 700)
            .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1), value: sorted.count)

            Spacer()
        }
        .padding(.horizontal, 120)
    }

    // MARK: - Gameplay

    private var gameplayView: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 60)
                    .padding(.top, 48)

                if let phase = gameVM.room?.status, phase != .roundOver {
                    TVStatusBadge(
                        phase: phase,
                        submittedCount: gameVM.roundSubmissions.count,
                        totalPlayers: max(0, gameVM.players.count - 1)
                    )
                    .padding(.top, 28)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                }

                Spacer()

                if gameVM.room?.status == .roundOver, let winner = roundWinner {
                    roundResultsView(winner: winner)
                } else if gameVM.room?.status == .judging {
                    judgingCardsView
                } else if let card = gameVM.currentBlackCard {
                    BlackCardView(text: card)
                        .font(.system(size: 36, weight: .bold))
                        .padding(.horizontal, 80)
                }

                Spacer()

                scoreboard
                    .padding(.horizontal, 60)
                    .padding(.bottom, 48)
            }

            VStack {
                Spacer()
                VStack(alignment: .center, spacing: 10) {
                    ForEach(chatStack, id: \.id) { chat in
                        TVChatBubble(chat: chat)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                    }
                }
                .padding(.bottom, 130)
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: chatStack.count)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Hot Takes Only")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(.pink)
                Text("Round \(gameVM.room?.currentRound ?? 1) of \(gameVM.room?.maxRounds ?? 5)")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            if let judge = gameVM.currentJudge {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Judge")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                    Text(judge.displayName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.yellow)
                }
            }
        }
    }

    // MARK: - Round Results

    private func roundResultsView(winner: (player: Player, cardText: String)) -> some View {
        VStack(spacing: 20) {
            if let prompt = gameVM.currentBlackCard {
                Text(prompt)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 80)
            }

            Text("🏆 \(winner.player.displayName) wins the round!")
                .font(.system(size: 32, weight: .black))
                .foregroundStyle(.yellow)

            Text(winner.cardText)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
                .padding(32)
                .frame(maxWidth: 700)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 80)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Judging Cards

    private var judgingCardsView: some View {
        VStack(spacing: 20) {
            if let card = gameVM.currentBlackCard {
                Text(card)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.35), lineWidth: 2))
                    .padding(.horizontal, 80)
            }

            // Sort by id for stable ordering across re-renders (hides submission order)
            let submissions = gameVM.roundSubmissions.sorted { $0.id.uuidString < $1.id.uuidString }
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 260, maximum: 360), spacing: 18)],
                spacing: 18
            ) {
                ForEach(Array(submissions.enumerated()), id: \.element.id) { i, sub in
                    if let text = SampleCards.white[safe: sub.cardIndex] {
                        TVWhiteCard(text: text, revealDelay: Double(i) * 0.1)
                    }
                }
            }
            .padding(.horizontal, 60)
        }
    }

    // MARK: - Scoreboard

    private var scoreboard: some View {
        let sorted = gameVM.players.sorted { $0.score > $1.score }.prefix(5)
        return HStack(spacing: 0) {
            ForEach(Array(sorted.enumerated()), id: \.element.id) { rank, player in
                HStack(spacing: 12) {
                    Text("\(rank + 1)")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                        .frame(width: 28)
                    Text(player.displayName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer()
                    Text("\(player.score)")
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .foregroundStyle(rank == 0 ? .pink : .white.opacity(0.7))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(rank == 0 ? Color.pink.opacity(0.12) : Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 6)
            }
        }
    }

    // MARK: - Helpers

    private var roundWinner: (player: Player, cardText: String)? {
        guard let winning = gameVM.roundSubmissions.first(where: { $0.isWinner }),
              let player = gameVM.players.first(where: { $0.id == winning.playerId }),
              let cardText = SampleCards.white[safe: winning.cardIndex]
        else { return nil }
        return (player, cardText)
    }
}

// MARK: - Status Badge

struct TVStatusBadge: View {
    let phase: GamePhase
    let submittedCount: Int
    let totalPlayers: Int
    @State private var glowOpacity: Double = 0.25

    var body: some View {
        HStack(spacing: 16) {
            WaveDots(color: phaseColor)

            VStack(alignment: .leading, spacing: 3) {
                Text(phaseText)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))

                if phase == .submitting && totalPlayers > 0 {
                    Text("\(submittedCount) of \(totalPlayers) cards submitted")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(phaseColor)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: submittedCount)
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
        .background(phaseColor.opacity(0.1))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(phaseColor.opacity(0.35), lineWidth: 1.5))
        .shadow(color: phaseColor.opacity(glowOpacity), radius: 24)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                glowOpacity = 0.75
            }
        }
    }

    private var phaseText: String {
        switch phase {
        case .waiting:    return "Waiting for players to join"
        case .submitting: return "Players are choosing their cards"
        case .judging:    return "The judge is selecting a winner"
        case .roundOver:  return ""
        case .finished:   return "Game over"
        }
    }

    private var phaseColor: Color {
        switch phase {
        case .waiting:    return .blue
        case .submitting: return .orange
        case .judging:    return .purple
        case .roundOver:  return .yellow
        case .finished:   return .pink
        }
    }
}

// MARK: - Wave Dots

struct WaveDots: View {
    let color: Color
    @State private var b0 = false
    @State private var b1 = false
    @State private var b2 = false

    var body: some View {
        HStack(spacing: 5) {
            dot(b0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true).delay(0.00)) { b0 = true }
                }
            dot(b1)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true).delay(0.15)) { b1 = true }
                }
            dot(b2)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true).delay(0.30)) { b2 = true }
                }
        }
    }

    private func dot(_ bouncing: Bool) -> some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .offset(y: bouncing ? -5 : 4)
            .opacity(bouncing ? 1.0 : 0.3)
    }
}

// MARK: - White Card (judging reveal)

struct TVWhiteCard: View {
    let text: String
    let revealDelay: Double
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(text)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.black)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .frame(minHeight: 120, alignment: .topLeading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .white.opacity(0.12), radius: 16, y: 4)
        .scaleEffect(appeared ? 1 : 0.6)
        .rotation3DEffect(.degrees(appeared ? 0 : -30), axis: (x: 0, y: 1, z: 0))
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.68).delay(revealDelay)) {
                appeared = true
            }
        }
    }
}

// MARK: - Chat Bubble

struct TVChatBubble: View {
    let chat: QuickChatMessage

    var body: some View {
        HStack(spacing: 14) {
            Text(chat.message)
                .font(.system(size: 26))
            VStack(alignment: .leading, spacing: 2) {
                Text(chat.from)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                Text("said")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.12), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 12, y: 4)
    }
}
