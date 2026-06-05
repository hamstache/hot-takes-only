import SwiftUI

struct WaitingRoomView: View {
    @EnvironmentObject var gameVM: GameViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                // Room code
                VStack(spacing: 4) {
                    Text("Room Code")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .textCase(.uppercase)
                    Text(gameVM.room?.code ?? "------")
                        .font(.system(size: 48, weight: .black, design: .monospaced))
                        .foregroundStyle(.pink)
                        .tracking(8)
                }
                .padding(.top, 48)

                Divider().overlay(.white.opacity(0.15))

                // Player list
                VStack(alignment: .leading, spacing: 0) {
                    Text("Players (\(gameVM.players.count))")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .textCase(.uppercase)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)

                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(gameVM.players) { player in
                                PlayerRow(player: player, isSelf: player.id == gameVM.myPlayer?.id)
                            }
                        }
                    }
                }

                Spacer()

                // Host controls
                VStack(spacing: 12) {
                    if gameVM.myPlayer?.isHost == true {
                        if gameVM.players.count < 2 {
                            Text("Waiting for at least 1 more player…")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.4))
                        }

                        HTButton("Start Game", color: .pink, isLoading: gameVM.isLoading) {
                            await gameVM.startGame()
                        }
                        .disabled(gameVM.players.count < 2)
                        .padding(.horizontal, 32)
                    } else {
                        Label("Waiting for host to start…", systemImage: "clock")
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    Button("Leave") {
                        gameVM.leaveRoom()
                    }
                    .foregroundStyle(.white.opacity(0.3))
                }
                .padding(.bottom, 40)
            }
        }
        .errorAlert(message: $gameVM.errorMessage)
    }
}

private struct PlayerRow: View {
    let player: Player
    let isSelf: Bool

    var body: some View {
        HStack {
            Circle()
                .fill(isSelf ? Color.pink : Color.white.opacity(0.2))
                .frame(width: 8, height: 8)
            Text(player.displayName)
                .foregroundStyle(.white)
            if player.isHost {
                Text("HOST")
                    .font(.caption2)
                    .foregroundStyle(.pink)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(.pink, lineWidth: 1))
            }
            Spacer()
            if isSelf {
                Text("You")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Divider().overlay(.white.opacity(0.08))
        }
    }
}
