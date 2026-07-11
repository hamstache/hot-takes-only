import SwiftUI

struct WaitingRoomView: View {
    @EnvironmentObject var gameVM: GameViewModel
    @Environment(\.horizontalSizeClass) private var hSizeClass

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if hSizeClass == .regular {
                iPadLayout
            } else {
                phoneLayout
            }
        }
        .errorAlert(message: $gameVM.errorMessage)
    }

    // MARK: - iPad layout (two-column)

    private var iPadLayout: some View {
        HStack(spacing: 0) {
            // Left: room code + controls
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 8) {
                    Text("Room Code")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .textCase(.uppercase)
                    Text(gameVM.room?.code ?? "------")
                        .font(.system(size: 64, weight: .black, design: .monospaced))
                        .foregroundStyle(.pink)
                        .tracking(10)
                    Text("Share this code with friends")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                }

                Spacer()

                Divider().overlay(.white.opacity(0.08))

                hostControls
                    .padding(.horizontal, 32)
                    .padding(.vertical, 32)
            }
            .frame(maxWidth: 340)
            .background(Color.white.opacity(0.03))

            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(width: 1)

            // Right: player list
            VStack(alignment: .leading, spacing: 0) {
                Text("Players (\(gameVM.players.count))")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .padding(.horizontal, 32)
                    .padding(.top, 32)
                    .padding(.bottom, 8)

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(gameVM.players) { player in
                            PlayerRow(player: player, isSelf: player.id == gameVM.myPlayer?.id)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Phone layout

    private var phoneLayout: some View {
        VStack(spacing: 24) {
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

            hostControls
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
        }
    }

    // MARK: - Shared

    private var hostControls: some View {
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
            } else {
                Label("Waiting for host to start…", systemImage: "clock")
                    .foregroundStyle(.white.opacity(0.5))
            }

            Button("Leave") { gameVM.leaveRoom() }
                .foregroundStyle(.white.opacity(0.3))
        }
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
