import SwiftUI

@main
struct HotTakesOnlyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appDelegate.gameVM)
                .task {
                    await AuthService.shared.ensureSession()
                }
        }
    }
}

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
        .alert("Not Enough Players", isPresented: $gameVM.shouldCancelGame) {
            Button("End Game", role: .destructive) {
                Task { await gameVM.cancelGame() }
            }
        } message: {
            Text("Everyone else has left. The game can't continue.")
        }
    }
}
