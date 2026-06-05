import SwiftUI

struct RoundResultsView: View {
    @EnvironmentObject var gameVM: GameViewModel

    private var winningSubmission: Submission? {
        gameVM.roundSubmissions.first(where: \.isWinner)
    }

    private var winner: Player? {
        guard let sub = winningSubmission else { return nil }
        return gameVM.players.first(where: { $0.id == sub.playerId })
    }

    var body: some View {
        VStack(spacing: 20) {
            if let sub = winningSubmission, let text = SampleCards.white[safe: sub.cardIndex] {
                WhiteCardView(text: text, isWinner: true)
                    .padding(.horizontal, 4)
                    .transition(.scale.combined(with: .opacity))
            }

            if let winner {
                VStack(spacing: 4) {
                    Text("🏆 \(winner.displayName) wins the round!")
                        .font(.headline)
                        .foregroundStyle(.yellow)
                    Text(winner.id == gameVM.myPlayer?.id ? "That's you! Nice." : "")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            // Scoreboard
            ScoreboardView()
                .padding(.top, 4)

            // Only judge (or host as fallback) advances
            if gameVM.isJudge || gameVM.myPlayer?.isHost == true {
                HTButton("Next Round →", color: .pink, isLoading: gameVM.isLoading) {
                    await gameVM.advanceRound()
                }
                .padding(.horizontal, 32)
            } else {
                Text("Waiting for judge to advance…")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 20)
    }
}
