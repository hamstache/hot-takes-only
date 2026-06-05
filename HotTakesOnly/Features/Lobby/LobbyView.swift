import SwiftUI

struct LobbyView: View {
    @EnvironmentObject var gameVM: GameViewModel

    @AppStorage("lastDisplayName") private var displayName = ""
    @State private var roomCode = ""
    @State private var isJoining = false
    @FocusState private var focusedField: Field?

    private enum Field { case name, code }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Title
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

                // Input fields
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
                .padding(.horizontal, 32)

                Spacer().frame(height: 24)

                // Action buttons
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
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .errorAlert(message: $gameVM.errorMessage)
        .onTapGesture { focusedField = nil }
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
