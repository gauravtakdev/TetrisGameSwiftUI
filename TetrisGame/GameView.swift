import SwiftUI

struct GameView: View {
    var onHome: () -> Void

    @StateObject private var engine = GameEngine()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 12) {
                header
                statsRow
                BoardView(engine: engine)
                controls
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            if engine.state == .paused { pauseOverlay }
            if engine.state == .gameOver { gameOverOverlay }
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active { engine.pause() }
        }
        .onDisappear { engine.shutdown() }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            TitleView(size: 34)
            Spacer()
            CircleIconButton(
                systemName: engine.soundOn ? "speaker.wave.2.fill" : "speaker.slash.fill",
                tint: Color(hex: 0x4C86E8)
            ) { engine.soundOn.toggle() }
            CircleIconButton(
                systemName: engine.vibrationOn ? "iphone.radiowaves.left.and.right" : "iphone.slash",
                tint: engine.vibrationOn ? Theme.accent : Theme.secondaryText
            ) { engine.vibrationOn.toggle() }
            CircleIconButton(systemName: "pause.fill") { engine.pause() }
        }
        .padding(.top, 4)
    }

    // MARK: Stats

    private var statsRow: some View {
        HStack(spacing: 8) {
            StatCard(title: "Score") { StatValue(value: engine.score) }
            StatCard(title: "Best") { StatValue(value: max(engine.best, engine.score), color: Theme.accent) }
            StatCard(title: "Level") { StatValue(value: engine.level) }
            StatCard(title: "Lines") { StatValue(value: engine.lines) }
            StatCard(title: "Next") {
                NextPreview(type: engine.next)
                    .frame(height: 28)
            }
        }
    }

    // MARK: Controls

    private var controls: some View {
        HStack(spacing: 10) {
            PadButton(action: { engine.moveLeft() }) {
                Image(systemName: "arrowtriangle.left.fill")
                    .font(.system(size: 22, weight: .bold)).foregroundColor(.white.opacity(0.9))
            }
            PadButton(action: { engine.moveRight() }) {
                Image(systemName: "arrowtriangle.right.fill")
                    .font(.system(size: 22, weight: .bold)).foregroundColor(.white.opacity(0.9))
            }
            PadButton(action: { engine.softDrop() }) {
                Image(systemName: "chevron.down.2")
                    .font(.system(size: 24, weight: .bold)).foregroundColor(.white.opacity(0.9))
            }
            PadButton(fill: Theme.accent, repeats: false, action: { engine.rotate() }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 24, weight: .bold)).foregroundColor(.black.opacity(0.8))
            }
            PadButton(fill: .clear, stroke: Theme.accent, repeats: false, action: { engine.hardDrop() }) {
                Text("DROP")
                    .font(.system(size: 15, weight: .heavy)).foregroundColor(Theme.accent)
            }
        }
    }

    // MARK: Overlays

    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Paused")
                    .font(.system(size: 40, weight: .bold))
                    .tracking(2)
                    .foregroundColor(.white)
                    .padding(.bottom, 8)
                PillButton(title: "Resume", style: .primary) { engine.resume() }
                PillButton(title: "Restart", style: .secondary) { engine.startNewGame() }
                PillButton(title: "Home", style: .outline) { onHome() }
            }
            .padding(28)
            .background(RoundedRectangle(cornerRadius: 28).fill(Theme.card))
            .padding(.horizontal, 28)
        }
        .transition(.opacity)
    }

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            VStack(spacing: 14) {
                Text("Game Over")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                Text("Score")
                    .font(.system(size: 13, weight: .semibold)).tracking(1.5)
                    .foregroundColor(Theme.secondaryText)
                Text("\(engine.score)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                if engine.isNewBest {
                    Text("New best score!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.accent)
                } else {
                    Text("Best \(engine.best)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.secondaryText)
                }
                PillButton(title: "Play Again", style: .primary) { engine.startNewGame() }
                    .padding(.top, 8)
                PillButton(title: "Home", style: .outline) { onHome() }
            }
            .padding(28)
            .background(RoundedRectangle(cornerRadius: 28).fill(Theme.card))
            .padding(.horizontal, 28)
        }
        .transition(.opacity)
    }
}
