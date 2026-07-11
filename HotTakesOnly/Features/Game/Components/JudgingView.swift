import SwiftUI

// Read-only card view for non-judge players during the judging phase
struct SpectatorJudgingView: View {
    @EnvironmentObject var gameVM: GameViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Submitted answers")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .textCase(.uppercase)
                Spacer()
                Image(systemName: "hourglass")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .symbolEffect(.pulse)
                Text("\(gameVM.currentJudge?.displayName ?? "Judge") is choosing…")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(gameVM.roundSubmissions) { submission in
                        if let text = SampleCards.white[safe: submission.cardIndex] {
                            WhiteCardView(text: text)
                                .frame(width: 200)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

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
