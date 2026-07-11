import SwiftUI

struct GameView: View {
    @EnvironmentObject var gameVM: GameViewModel
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @State private var showQuickChatMenu = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if hSizeClass == .regular {
                iPadLayout
            } else {
                phoneLayout
            }
        }
        .quickChatOverlay(showMenu: $showQuickChatMenu)
        .errorAlert(message: $gameVM.errorMessage)
    }

    // MARK: - iPad layout (two-column)

    private var iPadLayout: some View {
        HStack(spacing: 0) {
            // Left: header + black card
            VStack(spacing: 0) {
                GameHeader(showQuickChatMenu: $showQuickChatMenu)
                    .padding(.horizontal, 32)
                    .padding(.top, 24)
                    .padding(.bottom, 20)

                Divider().overlay(.white.opacity(0.1))

                Spacer().frame(height: 24)

                if let card = gameVM.currentBlackCard {
                    BlackCardView(text: card)
                        .padding(.horizontal, 32)
                }

                Spacer()
            }
            .frame(maxWidth: 420)
            .background(Color.white.opacity(0.02))

            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(width: 1)

            // Right: phase content
            VStack {
                Spacer().frame(height: 24)
                phaseContent
                    .padding(.horizontal, 32)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Phone layout

    private var phoneLayout: some View {
        VStack(spacing: 0) {
            GameHeader(showQuickChatMenu: $showQuickChatMenu)
                .padding(.horizontal, 20)
                .padding(.top, 16)

            Divider()
                .overlay(.white.opacity(0.1))
                .padding(.vertical, 12)

            if let card = gameVM.currentBlackCard {
                BlackCardView(text: card)
                    .padding(.horizontal, 20)
            }

            Spacer().frame(height: 20)

            phaseContent

            Spacer()
        }
    }

    // MARK: - Phase content (shared)

    @ViewBuilder
    private var phaseContent: some View {
        Group {
            switch gameVM.room?.status {
            case .submitting:
                submittingContent
            case .judging:
                judgingContent
            case .roundOver:
                RoundResultsView()
            default:
                EmptyView()
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .animation(.easeInOut(duration: 0.35), value: gameVM.room?.status)
    }

    @ViewBuilder
    private var submittingContent: some View {
        if gameVM.isJudge {
            VStack(spacing: 12) {
                Image(systemName: "eyes")
                    .font(.system(size: 40))
                    .foregroundStyle(.yellow)
                Text("You're the judge this round.")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Waiting for \(gameVM.players.count - 1) player(s) to submit…")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                SubmissionProgress()
                    .padding(.top, 8)
            }
            .padding(.horizontal, 12)
        } else if gameVM.hasSubmitted {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.green)
                Text("Card submitted!")
                    .font(.headline)
                    .foregroundStyle(.white)
                SubmissionProgress()
                    .padding(.top, 8)
            }
            .padding(.horizontal, 12)
        } else {
            HandView()
                .padding(.horizontal, hSizeClass == .regular ? 0 : 20)
        }
    }

    @ViewBuilder
    private var judgingContent: some View {
        if gameVM.isJudge {
            JudgingView()
                .padding(.horizontal, hSizeClass == .regular ? 0 : 20)
        } else {
            SpectatorJudgingView()
                .padding(.horizontal, hSizeClass == .regular ? 0 : 20)
        }
    }
}

// MARK: - Header

private struct GameHeader: View {
    @EnvironmentObject var gameVM: GameViewModel
    @Binding var showQuickChatMenu: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Round \(gameVM.room?.currentRound ?? 1) of \(gameVM.room?.maxRounds ?? 5)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                if let judge = gameVM.currentJudge {
                    Text(gameVM.isJudge ? "You're judging" : "\(judge.displayName) is judging")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.yellow)
                }
            }
            Spacer()
            ReactionsButton(showMenu: $showQuickChatMenu)
                .padding(.trailing, 6)
            if gameVM.voiceChat.isConnected {
                PushToTalkButton()
                    .padding(.trailing, 8)
            }
            ScorePill()
        }
    }
}

private struct ReactionsButton: View {
    @Binding var showMenu: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showMenu.toggle()
            }
        } label: {
            Image(systemName: "face.smiling")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
                .padding(8)
                .background(Color.white.opacity(0.08))
                .clipShape(Circle())
        }
    }
}

private struct PushToTalkButton: View {
    @EnvironmentObject var gameVM: GameViewModel

    var body: some View {
        let speaking = gameVM.voiceChat.isSpeaking
        Image(systemName: speaking ? "mic.fill" : "mic.slash.fill")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(speaking ? .green : .white.opacity(0.4))
            .padding(8)
            .background(speaking ? Color.green.opacity(0.2) : Color.white.opacity(0.08))
            .clipShape(Circle())
            .animation(.easeInOut(duration: 0.15), value: speaking)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !gameVM.voiceChat.isSpeaking { gameVM.voiceChat.beginSpeaking() }
                    }
                    .onEnded { _ in gameVM.voiceChat.endSpeaking() }
            )
    }
}

private struct ScorePill: View {
    @EnvironmentObject var gameVM: GameViewModel

    var body: some View {
        HStack(spacing: 6) {
            ForEach(gameVM.players.sorted(by: { $0.score > $1.score }).prefix(3)) { player in
                Text("\(player.displayName.prefix(1))\(player.score)")
                    .font(.caption.monospaced())
                    .foregroundStyle(player.id == gameVM.myPlayer?.id ? .pink : .white)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.white.opacity(0.1))
        .clipShape(Capsule())
    }
}

private struct SubmissionProgress: View {
    @EnvironmentObject var gameVM: GameViewModel

    var body: some View {
        let submitted = gameVM.roundSubmissions.count
        let total = max(gameVM.players.count - 1, 1)

        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3)
                    .fill(i < submitted ? Color.green : Color.white.opacity(0.2))
                    .frame(height: 6)
                    .animation(.easeInOut, value: submitted)
            }
        }
    }
}
