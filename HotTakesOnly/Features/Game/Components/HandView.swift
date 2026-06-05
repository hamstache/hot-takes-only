import SwiftUI

struct HandView: View {
    @EnvironmentObject var gameVM: GameViewModel
    @State private var selectedIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pick your best answer")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(gameVM.myHand.enumerated()), id: \.offset) { index, text in
                        WhiteCardView(
                            text: text,
                            isSelected: selectedIndex == index,
                            onTap: { selectedIndex = (selectedIndex == index ? nil : index) }
                        )
                        .frame(width: 200)
                    }
                }
                .padding(.vertical, 4)
            }

            if let idx = selectedIndex {
                HTButton("Submit This Card", color: .pink, isLoading: gameVM.isLoading) {
                    await gameVM.submitCard(handIndex: idx)
                    selectedIndex = nil
                }
            }
        }
    }
}
