import SwiftUI

struct WhiteCardView: View {
    let text: String
    var isSelected: Bool = false
    var isWinner: Bool = false
    let onTap: (() -> Void)?

    init(text: String, isSelected: Bool = false, isWinner: Bool = false, onTap: (() -> Void)? = nil) {
        self.text = text
        self.isSelected = isSelected
        self.isWinner = isWinner
        self.onTap = onTap
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(isWinner ? Color.yellow : .white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.pink : .clear, lineWidth: 3)
                    )
                    .shadow(color: isSelected ? .pink.opacity(0.4) : .black.opacity(0.3), radius: 8)

                VStack(alignment: .leading, spacing: 0) {
                    if isWinner {
                        Label("Winner!", systemImage: "trophy.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.black.opacity(0.6))
                            .padding(.bottom, 6)
                    }

                    Text(text)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.black)
                        .lineSpacing(3)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer(minLength: 8)

                    HStack {
                        Spacer()
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.pink.opacity(0.4))
                            .font(.caption2)
                    }
                }
                .padding(16)
            }
            .frame(minHeight: 120)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}
