import SwiftUI

// MARK: - Model

struct QuickChatMessage: Equatable {
    let id = UUID()
    let from: String
    let message: String

    static func == (lhs: QuickChatMessage, rhs: QuickChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Options

let quickChatOptions = ["😂 Dead", "🔥 Hot take!", "👀 No way", "💀 I'm done", "🏆 Easy win", "😤 Rigged"]

// MARK: - Radial Menu

struct RadialMenuView: View {
    @EnvironmentObject var gameVM: GameViewModel
    @Binding var isShowing: Bool
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            ZStack {
                ForEach(quickChatOptions.indices, id: \.self) { i in
                    let angle = Angle.degrees(Double(i) * 60.0 - 90.0)
                    let radius: CGFloat = 108

                    Button {
                        Task { await gameVM.sendQuickChat(quickChatOptions[i]) }
                        dismiss()
                    } label: {
                        Text(quickChatOptions[i])
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 1))
                    }
                    .scaleEffect(appeared ? 1 : 0.1)
                    .opacity(appeared ? 1 : 0)
                    .offset(
                        x: cos(angle.radians) * radius,
                        y: sin(angle.radians) * radius
                    )
                    .animation(
                        .spring(response: 0.35, dampingFraction: 0.65).delay(Double(i) * 0.04),
                        value: appeared
                    )
                }

                // Center close indicator
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(14)
                    .background(.ultraThinMaterial, in: Circle())
                    .onTapGesture { dismiss() }
            }
        }
        .onAppear { appeared = true }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.15)) { isShowing = false }
    }
}

// MARK: - Toast

struct QuickChatToast: View {
    let message: QuickChatMessage

    var body: some View {
        HStack(spacing: 6) {
            Text(message.message)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Text("· \(message.from)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.12), lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }
}

// MARK: - ViewModifier

struct QuickChatOverlayModifier: ViewModifier {
    @EnvironmentObject var gameVM: GameViewModel
    @Binding var showMenu: Bool

    func body(content: Content) -> some View {
        ZStack {
            content

            if showMenu {
                RadialMenuView(isShowing: $showMenu)
                    .transition(.opacity)
                    .zIndex(10)
            }

            VStack {
                if let chat = gameVM.latestQuickChat {
                    QuickChatToast(message: chat)
                        .padding(.top, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: gameVM.latestQuickChat)
            .allowsHitTesting(false)
            .zIndex(9)
        }
    }
}

extension View {
    func quickChatOverlay(showMenu: Binding<Bool>) -> some View {
        modifier(QuickChatOverlayModifier(showMenu: showMenu))
    }
}
