import SwiftUI

struct ScoreboardView: View {
    @EnvironmentObject var gameVM: GameViewModel

    private var sortedPlayers: [Player] {
        gameVM.players.sorted { $0.score > $1.score }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Scores")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
                .padding(.bottom, 8)

            ForEach(Array(sortedPlayers.enumerated()), id: \.element.id) { rank, player in
                HStack {
                    Text("\(rank + 1)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.white.opacity(0.3))
                        .frame(width: 20)

                    Text(player.displayName)
                        .foregroundStyle(player.id == gameVM.myPlayer?.id ? .pink : .white)
                        .fontWeight(player.id == gameVM.myPlayer?.id ? .semibold : .regular)

                    if player.id == gameVM.currentJudge?.id {
                        Image(systemName: "eyes")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }

                    Spacer()

                    Text("\(player.score) pt\(player.score == 1 ? "" : "s")")
                        .font(.body.monospaced().weight(.bold))
                        .foregroundStyle(player.id == gameVM.myPlayer?.id ? .pink : .white)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 4)
                .overlay(alignment: .bottom) {
                    Divider().overlay(.white.opacity(0.08))
                }
            }
        }
    }
}
