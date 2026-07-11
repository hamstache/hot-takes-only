import SwiftUI

struct FinalScoreView: View {
    @EnvironmentObject var gameVM: GameViewModel
    @State private var confettiTrigger = 0
    @State private var showContent = false

    private var frozenPlayers: [Player] {
        gameVM.finalPlayers ?? gameVM.players
    }

    private var topPlayer: Player? {
        frozenPlayers.max(by: { $0.score < $1.score })
    }

    private var isWinner: Bool {
        topPlayer?.id == gameVM.myPlayer?.id
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Winner callout
                VStack(spacing: 12) {
                    Text(isWinner ? "🎉" : "🏆")
                        .font(.system(size: 72))
                        .scaleEffect(showContent ? 1 : 0.3)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: showContent)

                    if let top = topPlayer {
                        Group {
                            if isWinner {
                                VStack(spacing: 6) {
                                    Text("You won!")
                                        .font(.system(size: 40, weight: .black))
                                        .foregroundStyle(.yellow)
                                    Text("Not bad for someone with your opinions.")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.5))
                                        .multilineTextAlignment(.center)
                                }
                            } else {
                                VStack(spacing: 6) {
                                    Text("\(top.displayName) wins!")
                                        .font(.system(size: 36, weight: .black))
                                        .foregroundStyle(.yellow)
                                    Text("With \(top.score) point\(top.score == 1 ? "" : "s"). Respect.")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                            }
                        }
                        .offset(y: showContent ? 0 : 20)
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.25), value: showContent)
                    }
                }

                // Final scoreboard
                ScoreboardView(players: frozenPlayers)
                    .padding(.horizontal, 32)
                    .offset(y: showContent ? 0 : 30)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.4), value: showContent)

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
                .offset(y: showContent ? 0 : 20)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.55), value: showContent)
            }

            // Full-screen confetti for final winner
            ConfettiView(trigger: confettiTrigger, intensity: isWinner ? 2.0 : 1.2)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .onAppear {
            showContent = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                confettiTrigger += 1
                UINotificationFeedbackGenerator().notificationOccurred(isWinner ? .success : .warning)
            }
        }
    }
}
