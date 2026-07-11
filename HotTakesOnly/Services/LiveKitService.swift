import Foundation
import Combine

// Voice chat is deferred until post-launch. This stub preserves the existing
// call sites in GameViewModel and GameView so no other files need to change.
@MainActor
final class LiveKitService: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var isSpeaking = false
    @Published var activeSpeakerNames: Set<String> = []

    func connect(roomId: String, displayName: String) async {}
    func disconnect() {}
    func beginSpeaking() {}
    func endSpeaking() {}
}
