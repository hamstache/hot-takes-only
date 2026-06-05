import SwiftUI

struct FinalScoreView: View {
    @EnvironmentObject var gameVM: GameViewModel

    private var topPlayer: Player? {
        gameVM.players.max(by: { $0.score < $1.score })
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Winner callout
                VStack(spacing: 12) {
                    Text("🏆")
                        .font(.system(size: 72))

                    if let top = topPlayer {
                        if top.id == gameVM.myPlayer?.id {
                            Text("You won!")
                                .font(.system(size: 40, weight: .black))
                                .foregroundStyle(.yellow)
                            Text("Not bad for someone with your opinions.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                        } else {
                            Text("\(top.displayName) wins!")
                                .font(.system(size: 36, weight: .black))
                                .foregroundStyle(.yellow)
                            Text("With \(top.score) points. Respect.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }

                // Final scoreboard
                ScoreboardView()
                    .padding(.horizontal, 32)

                Spacer()

                // Play again / leave
                VStack(spacing: 12) {
                    if gameVM.myPlayer?.isHost == true {
                        HTButton("Play Again", color: .pink, isLoading: gameVM.isLoading) {
                            await gameVM.playAgain()
                        }
                        .padding(.horizontal, 32)
                    } else {
                        HTButton("Play Again", color: .pink, isLoading: false) {
                            gameVM.leaveRoom()
                        }
                        .padding(.horizontal, 32)
                        Text("Your name is saved — join the new room code from the host.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    Button("Leave") {
                        gameVM.leaveRoom()
                    }
                    .foregroundStyle(.white.opacity(0.3))
                }
                .padding(.bottom, 40)
            }
        }
    }
}
