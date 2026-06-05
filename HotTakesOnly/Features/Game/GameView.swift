import SwiftUI

// Container that switches between sub-views based on game phase and role.
struct GameView: View {
    @EnvironmentObject var gameVM: GameViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                GameHeader()
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                Divider()
                    .overlay(.white.opacity(0.1))
                    .padding(.vertical, 12)

                // Black card always visible
                if let card = gameVM.currentBlackCard {
                    BlackCardView(text: card)
                        .padding(.horizontal, 20)
                }

                Spacer().frame(height: 20)

                // Phase-specific content
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

                Spacer()
            }
        }
        .errorAlert(message: $gameVM.errorMessage)
    }

    // MARK: - Phase content

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
            .padding(.horizontal, 32)
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
            .padding(.horizontal, 32)
        } else {
            HandView()
                .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private var judgingContent: some View {
        if gameVM.isJudge {
            JudgingView()
                .padding(.horizontal, 20)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "hourglass")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)
                    .symbolEffect(.rotate)
                Text("\(gameVM.currentJudge?.displayName ?? "Judge") is choosing…")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
    }
}

// MARK: - Header

private struct GameHeader: View {
    @EnvironmentObject var gameVM: GameViewModel

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
            ScorePill()
        }
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
