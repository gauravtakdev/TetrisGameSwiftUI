import SwiftUI

struct HomeView: View {
    let best: Int
    let onPlay: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                TitleView(size: 64)
                    .padding(.top, 70)
                    .padding(.bottom, 10)

                VStack(spacing: 10) {
                    Text("BEST SCORE")
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(3)
                        .foregroundColor(Theme.secondaryText)
                    Text("\(best)")
                        .font(.system(size: 54, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(card)

                Button(action: onPlay) {
                    HStack(spacing: 14) {
                        Image(systemName: "play.fill")
                        Text("PLAY").tracking(3)
                    }
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(Color.black.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .frame(height: 68)
                    .background(Capsule().fill(Theme.accent))
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 12) {
                    Text("How To Play")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.bottom, 2)
                    ForEach(tips, id: \.self) { tip in
                        Text("•  \(tip)")
                            .font(.system(size: 17))
                            .foregroundColor(Theme.secondaryText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
                .background(card)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }

    private let tips = [
        "Swipe left / right to move",
        "Swipe down to soft drop",
        "Flick down fast to hard drop",
        "Tap the board to rotate"
    ]

    private var card: some View {
        RoundedRectangle(cornerRadius: 28)
            .fill(Theme.card)
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(Theme.cardBorder, lineWidth: 1))
    }
}
