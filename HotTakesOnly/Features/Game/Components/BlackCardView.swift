import SwiftUI

struct BlackCardView: View {
    let text: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: .white.opacity(0.05), radius: 16)

            VStack(alignment: .leading, spacing: 12) {
                Text(text)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.pink)
                    Text("Hot Takes Only")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .padding(20)
        }
        .frame(minHeight: 160)
    }
}
