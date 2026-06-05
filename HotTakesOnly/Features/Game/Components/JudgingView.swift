import SwiftUI

struct JudgingView: View {
    @EnvironmentObject var gameVM: GameViewModel
    @State private var selectedSubmission: Submission?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pick the best answer")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(gameVM.roundSubmissions) { submission in
                        if let text = SampleCards.white[safe: submission.cardIndex] {
                            WhiteCardView(
                                text: text,
                                isSelected: selectedSubmission?.id == submission.id,
                                onTap: {
                                    selectedSubmission = (selectedSubmission?.id == submission.id
                                        ? nil
                                        : submission)
                                }
                            )
                            .frame(width: 200)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            if let sub = selectedSubmission {
                HTButton("Choose This Card", color: .yellow, isLoading: gameVM.isLoading) {
                    await gameVM.pickWinner(sub)
                    selectedSubmission = nil
                }
            }
        }
    }
}
