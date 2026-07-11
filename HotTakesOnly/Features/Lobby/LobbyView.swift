import SwiftUI

struct LobbyView: View {
    @EnvironmentObject var gameVM: GameViewModel
    @ObservedObject private var auth = AuthService.shared
    @Environment(\.horizontalSizeClass) private var hSizeClass

    @AppStorage("lastDisplayName") private var displayName = ""
    @State private var roomCode = ""
    @State private var isJoining = false
    @FocusState private var focusedField: Field?

    private enum Field { case name, code }

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
        .onTapGesture { focusedField = nil }
    }

    // MARK: - iPad layout (two-column)

    private var iPadLayout: some View {
        HStack(spacing: 0) {
            // Left: branding panel
            VStack(spacing: 24) {
                Spacer()
                Text("🔥")
                    .font(.system(size: 96))
                Text("Hot Takes Only")
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("Cards. Chaos. No context needed.")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                Spacer()
                Text("Best with 3–8 players.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.25))
                    .padding(.bottom, 48)
            }
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.pink.opacity(0.15), Color.black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(width: 1)

            // Right: form panel
            ScrollView {
                VStack(spacing: 28) {
                    Spacer().frame(height: 60)

                    Text("Let's play")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    formFields
                    actionButtons
                    siwaSection
                    Spacer().frame(height: 60)
                }
                .padding(.horizontal, 48)
            }
            .frame(maxWidth: 480)
        }
    }

    // MARK: - Phone layout

    private var phoneLayout: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text("🔥")
                    .font(.system(size: 64))
                Text("Hot Takes Only")
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(.white)
                Text("Cards. Chaos. No context needed.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer().frame(height: 48)
            formFields.padding(.horizontal, 32)
            Spacer().frame(height: 24)
            actionButtons.padding(.horizontal, 32)
            Spacer().frame(height: 24)
            siwaSection.padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - Shared subviews

    private var formFields: some View {
        VStack(spacing: 12) {
            HTextField(placeholder: "Your name", text: $displayName)
                .focused($focusedField, equals: .name)

            if isJoining {
                HTextField(placeholder: "Room code", text: $roomCode)
                    .focused($focusedField, equals: .code)
                    .textInputAutocapitalization(.characters)
                    .onChange(of: roomCode) { _, new in
                        roomCode = String(new.uppercased().prefix(6))
                    }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if isJoining {
                HTButton("Join Game", color: .green, isLoading: gameVM.isLoading) {
                    await gameVM.joinRoom(code: roomCode, displayName: displayName)
                }
                .disabled(displayName.trimmed.isEmpty || roomCode.count != 6)

                Button("Back") {
                    withAnimation { isJoining = false }
                }
                .foregroundStyle(.white.opacity(0.5))
            } else {
                HTButton("Create Game", color: .pink, isLoading: gameVM.isLoading) {
                    await gameVM.createRoom(displayName: displayName)
                }
                .disabled(displayName.trimmed.isEmpty)

                HTButton("Join Game", color: .blue, isLoading: false) {
                    withAnimation { isJoining = true }
                }
                .disabled(displayName.trimmed.isEmpty)
            }
        }
    }

    private var siwaSection: some View {
        VStack(spacing: 12) {
            HStack {
                Rectangle().frame(height: 1).foregroundStyle(.white.opacity(0.15))
                Text("or").font(.caption).foregroundStyle(.white.opacity(0.4))
                Rectangle().frame(height: 1).foregroundStyle(.white.opacity(0.15))
            }

            if auth.isSignedInWithApple {
                Label("Signed in with Apple", systemImage: "checkmark.seal.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                Button {
                    Task {
                        if let name = await AuthService.shared.signInWithApple(),
                           displayName.trimmed.isEmpty {
                            displayName = name
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                        Text("Sign in with Apple")
                            .font(.headline)
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}

// MARK: - Reusable components

struct HTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(.white.opacity(0.1))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .tint(.pink)
    }
}

struct HTButton: View {
    let title: String
    let color: Color
    let isLoading: Bool
    let action: () async -> Void

    init(_ title: String, color: Color, isLoading: Bool, action: @escaping () async -> Void) {
        self.title = title
        self.color = color
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            ZStack {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - View modifiers

extension View {
    func errorAlert(message: Binding<String?>) -> some View {
        alert("Something went wrong", isPresented: .constant(message.wrappedValue != nil)) {
            Button("OK") { message.wrappedValue = nil }
        } message: {
            Text(message.wrappedValue ?? "")
        }
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespaces) }
}
