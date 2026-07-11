import SwiftUI

struct RoundResultsView: View {
    @EnvironmentObject var gameVM: GameViewModel
    @State private var confettiTrigger = 0
    @State private var confettiFired = false

    private var winningSubmission: Submission? {
        gameVM.roundSubmissions.first(where: \.isWinner)
    }

    private var winner: Player? {
        guard let sub = winningSubmission else { return nil }
        return gameVM.players.first(where: { $0.id == sub.playerId })
    }

    private func fireConfetti() {
        guard !confettiFired, winner?.id == gameVM.myPlayer?.id else { return }
        confettiFired = true
        confettiTrigger += 1
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    var body: some View {
        ZStack {
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

                ScoreboardView()
                    .padding(.top, 4)

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

            // Confetti burst — fires once when winner is revealed
            ConfettiView(trigger: confettiTrigger, intensity: 0.6)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .onAppear {
            // Guest path: winner already set by the time the view appears
            if winningSubmission != nil {
                fireConfetti()
            }
        }
        .onChange(of: winningSubmission?.id) { _, newVal in
            // Host/slow-network path: winner arrives after view appears
            if newVal != nil { fireConfetti() }
        }
    }
}
