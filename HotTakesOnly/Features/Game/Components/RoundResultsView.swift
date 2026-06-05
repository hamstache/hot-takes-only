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

            // All players must ready up before the round advances
            if gameVM.myPlayer?.isReady == true {
                Text("Waiting for others… (\(gameVM.players.filter(\.isReady).count)/\(gameVM.players.count) ready)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            } else {
                HTButton("Ready for Next Round →", color: .pink, isLoading: gameVM.isLoading) {
                    await gameVM.readyForNextRound()
                }
                .padding(.horizontal, 32)
            }
        }
        .padding(.horizontal, 20)
    }
}
