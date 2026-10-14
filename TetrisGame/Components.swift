import SwiftUI

// MARK: - Title

struct TitleView: View {
    var size: CGFloat
    private let letters = Array("TETRIS")
    private let colors: [Color] = [
        Color(hex: 0xE8503A), Color(hex: 0xF29B30), Color(hex: 0xF2D13C),
        Color(hex: 0x6DC95A), Color(hex: 0x4FC1C8), Color(hex: 0xA25BDB)
    ]

    var body: some View {
        HStack(spacing: size * 0.02) {
            ForEach(0..<letters.count, id: \.self) { i in
                Text(String(letters[i])).foregroundColor(colors[i])
            }
        }
        .font(.system(size: size, weight: .black, design: .rounded))
        .shadow(color: Color.orange.opacity(0.45), radius: size * 0.12)
    }
}

// MARK: - Block painter (3D-style glossy block)

enum BlockPainter {
    static func draw(_ ctx: GraphicsContext, rect: CGRect, color: Color) {
        let r = rect.insetBy(dx: rect.width * 0.06, dy: rect.height * 0.06)
        let path = Path(roundedRect: r, cornerRadius: r.width * 0.22)
        ctx.fill(path, with: .linearGradient(
            Gradient(colors: [color.opacity(0.95), color.opacity(0.65)]),
            startPoint: CGPoint(x: r.minX, y: r.minY),
            endPoint: CGPoint(x: r.maxX, y: r.maxY)))
        ctx.stroke(path, with: .color(Color.white.opacity(0.35)), lineWidth: 1.5)
        let shine = CGRect(x: r.minX + r.width * 0.2, y: r.minY + r.height * 0.16,
                           width: r.width * 0.32, height: r.height * 0.16)
        ctx.fill(Path(roundedRect: shine, cornerRadius: shine.height / 2),
                 with: .color(Color.white.opacity(0.55)))
    }

    static func drawGhost(_ ctx: GraphicsContext, rect: CGRect, color: Color) {
        let r = rect.insetBy(dx: rect.width * 0.08, dy: rect.height * 0.08)
        let path = Path(roundedRect: r, cornerRadius: r.width * 0.22)
        ctx.fill(path, with: .color(color.opacity(0.12)))
        ctx.stroke(path, with: .color(color.opacity(0.8)), lineWidth: 1.5)
    }
}

// MARK: - Next piece preview

struct NextPreview: View {
    let type: Tetromino

    var body: some View {
        Canvas { ctx, size in
            let cells = Piece(type: type, rotation: 0, x: 0, y: 0).cells
            let minX = cells.map { $0.x }.min() ?? 0
            let maxX = cells.map { $0.x }.max() ?? 0
            let minY = cells.map { $0.y }.min() ?? 0
            let maxY = cells.map { $0.y }.max() ?? 0
            let cs = min(size.width / 4, size.height / 2)
            let w = CGFloat(maxX - minX + 1) * cs
            let h = CGFloat(maxY - minY + 1) * cs
            let ox = (size.width - w) / 2
            let oy = (size.height - h) / 2
            for c in cells {
                let rect = CGRect(x: ox + CGFloat(c.x - minX) * cs,
                                  y: oy + CGFloat(c.y - minY) * cs,
                                  width: cs, height: cs)
                BlockPainter.draw(ctx, rect: rect, color: type.color)
            }
        }
    }
}

// MARK: - Buttons

struct CircleIconButton: View {
    let systemName: String
    var tint: Color = .white
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(tint)
                .frame(width: 48, height: 48)
                .background(Circle().fill(Theme.button.opacity(0.8)))
        }
        .buttonStyle(.plain)
    }
}

struct PillButton: View {
    enum Style { case primary, secondary, outline }
    let title: String
    var style: Style = .primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(foreground)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Capsule().fill(fill))
                .overlay(Capsule().stroke(Theme.accent, lineWidth: style == .outline ? 1.5 : 0))
        }
        .buttonStyle(.plain)
    }

    private var fill: Color {
        switch style {
        case .primary: return Theme.accent
        case .secondary: return Theme.button
        case .outline: return .clear
        }
    }

    private var foreground: Color {
        switch style {
        case .primary: return Color.black.opacity(0.85)
        case .secondary: return .white
        case .outline: return Theme.accent
        }
    }
}

/// Control-pad button that fires once on touch-down and repeats while held.
struct PadButton<Content: View>: View {
    var fill: Color = Theme.button
    var stroke: Color? = nil
    var repeats: Bool = true
    let action: () -> Void
    @ViewBuilder var content: () -> Content

    @State private var pressed = false
    @State private var delayTimer: Timer?
    @State private var repeatTimer: Timer?

    var body: some View {
        content()
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .background(RoundedRectangle(cornerRadius: 18).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: 18)
                .stroke(stroke ?? .clear, lineWidth: stroke == nil ? 0 : 2))
            .scaleEffect(pressed ? 0.94 : 1)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !pressed else { return }
                        pressed = true
                        action()
                        if repeats { startRepeating() }
                    }
                    .onEnded { _ in stop() }
            )
            .onDisappear { stop() }
    }

    private func startRepeating() {
        delayTimer = Timer.scheduledTimer(withTimeInterval: 0.22, repeats: false) { _ in
            repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.07, repeats: true) { _ in
                action()
            }
        }
    }

    private func stop() {
        pressed = false
        delayTimer?.invalidate(); delayTimer = nil
        repeatTimer?.invalidate(); repeatTimer = nil
    }
}

// MARK: - Cards

struct StatCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundColor(Theme.secondaryText)
            content()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.card))
    }
}

struct StatValue: View {
    let value: Int
    var color: Color = .white
    var body: some View {
        Text("\(value)")
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundColor(color)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
    }
}
