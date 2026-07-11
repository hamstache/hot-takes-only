import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    static weak var shared: AppDelegate?
    let gameVM = GameViewModel()

    private var disconnectWorkItem: DispatchWorkItem?
    private var backgroundTaskId = UIBackgroundTaskIdentifier.invalid

    override init() {
        super.init()
        AppDelegate.shared = self
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        if connectingSceneSession.role == .windowExternalDisplayNonInteractive {
            return UISceneConfiguration(name: "External Display Configuration", sessionRole: connectingSceneSession.role)
        }
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    // Called whenever the app leaves the foreground — backgrounding, screen lock, force-quit.
    // Start a background task so we keep running after the app is "killed", then fire a
    // 30-second grace timer. If the user returns before it fires, cancel it. If not (true
    // kill / stayed away), delete the player row so Realtime notifies everyone.
    func applicationDidEnterBackground(_ application: UIApplication) {
        backgroundTaskId = application.beginBackgroundTask { [weak self] in
            self?.cancelDisconnect()
            self?.endBackgroundTask(application)
        }

        let work = DispatchWorkItem { [weak self] in
            self?.performLeave(application: application)
        }
        disconnectWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 30, execute: work)
    }

    // User came back — cancel pending disconnect.
    func applicationWillEnterForeground(_ application: UIApplication) {
        cancelDisconnect()
        endBackgroundTask(application)
    }

    // Last-chance fallback for cases where the OS terminates without backgrounding first.
    func applicationWillTerminate(_ application: UIApplication) {
        cancelDisconnect()
        let playerId = MainActor.assumeIsolated { AppDelegate.shared?.gameVM.myPlayer?.id }
        guard let playerId else { return }
        let sema = DispatchSemaphore(value: 0)
        Task.detached {
            do {
                try await SupabaseService.shared.client
                    .from("players")
                    .delete()
                    .eq("id", value: playerId.uuidString)
                    .execute()
            } catch {}
            sema.signal()
        }
        _ = sema.wait(timeout: .now() + 4)
    }

    private func cancelDisconnect() {
        disconnectWorkItem?.cancel()
        disconnectWorkItem = nil
    }

    private func performLeave(application: UIApplication) {
        disconnectWorkItem = nil
        let playerId = MainActor.assumeIsolated { AppDelegate.shared?.gameVM.myPlayer?.id }
        guard let playerId else { endBackgroundTask(application); return }

        Task.detached {
            do {
                try await SupabaseService.shared.client
                    .from("players")
                    .delete()
                    .eq("id", value: playerId.uuidString)
                    .execute()
            } catch {}
            await MainActor.run {
                AppDelegate.shared?.gameVM.leaveRoom()
                AppDelegate.shared?.endBackgroundTask(application)
            }
        }
    }

    private func endBackgroundTask(_ application: UIApplication) {
        guard backgroundTaskId != .invalid else { return }
        application.endBackgroundTask(backgroundTaskId)
        backgroundTaskId = .invalid
    }
}
