import SwiftUI

@main
struct HotTakesOnlyApp: App {
    @StateObject private var gameVM = GameViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(gameVM)
        }
    }
}

// Drives navigation purely from game state — no NavigationPath needed.
struct RootView: View {
    @EnvironmentObject var gameVM: GameViewModel

    var body: some View {
        Group {
            switch gameVM.room?.status {
            case .none:
                LobbyView()
            case .waiting:
                WaitingRoomView()
            case .submitting, .judging, .roundOver:
                GameView()
            case .finished:
                FinalScoreView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: gameVM.room?.status)
    }
}
