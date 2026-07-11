import UIKit
import SwiftUI

class ExternalDisplaySceneDelegate: NSObject, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene,
              let gameVM = AppDelegate.shared?.gameVM else { return }
        let win = UIWindow(windowScene: windowScene)
        win.rootViewController = UIHostingController(
            rootView: TVGameView().environmentObject(gameVM)
        )
        self.window = win
        win.makeKeyAndVisible()
    }
}
