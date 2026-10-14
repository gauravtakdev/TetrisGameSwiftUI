import SwiftUI

/// Renders the board and handles touch gestures:
/// swipe left/right = move, swipe down = soft drop, fast flick down = hard drop, tap = rotate.
struct BoardView: View {
    @ObservedObject var engine: GameEngine

    @State private var processedX: CGFloat = 0
    @State private var processedY: CGFloat = 0
    @State private var didMove = false

    var body: some View {
        GeometryReader { geo in
            let cols = GameEngine.cols
            let rows = GameEngine.rows
            let cell = min(geo.size.width / CGFloat(cols), geo.size.height / CGFloat(rows))
            let boardW = cell * CGFloat(cols)
            let boardH = cell * CGFloat(rows)

            Canvas { ctx, _ in
                // faint column lines
                for c in 1..<cols {
                    var line = Path()
                    line.move(to: CGPoint(x: CGFloat(c) * cell, y: 0))
                    line.addLine(to: CGPoint(x: CGFloat(c) * cell, y: boardH))
                    ctx.stroke(line, with: .color(Color.white.opacity(0.04)), lineWidth: 1)
                }

                // locked blocks
                for r in 0..<rows {
                    for c in 0..<cols {
                        if let t = engine.board[r][c] {
                            BlockPainter.draw(ctx, rect: rect(c, r, cell), color: t.color)
                        }
                    }
                }

                // ghost + active piece
                if let p = engine.current, engine.state != .gameOver {
                    for g in engine.ghostCells where g.y >= 0 {
                        BlockPainter.drawGhost(ctx, rect: rect(g.x, g.y, cell), color: p.type.color)
                    }
                    for c in p.cells where c.y >= 0 {
                        BlockPainter.draw(ctx, rect: rect(c.x, c.y, cell), color: p.type.color)
                    }
                }
            }
            .frame(width: boardW, height: boardH)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(LinearGradient(colors: [Theme.boardTop, Theme.boardBottom],
                                         startPoint: .top, endPoint: .bottom))
            )
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.18), lineWidth: 1.5))
            .contentShape(Rectangle())
            .gesture(boardGesture(cell: cell))
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }

    private func rect(_ c: Int, _ r: Int, _ cell: CGFloat) -> CGRect {
        CGRect(x: CGFloat(c) * cell, y: CGFloat(r) * cell, width: cell, height: cell)
    }

    private func boardGesture(cell: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { v in
                let tx = v.translation.width
                let ty = v.translation.height
                if abs(tx) > 12 || abs(ty) > 12 { didMove = true }

                while tx - processedX >= cell {
                    engine.moveRight()
                    processedX += cell
                }
                while processedX - tx >= cell {
                    engine.moveLeft()
                    processedX -= cell
                }
                while ty - processedY >= cell {
                    engine.softDrop()
                    processedY += cell
                }
            }
            .onEnded { v in
                let ty = v.translation.height
                let flick = v.predictedEndTranslation.height - ty
                if !didMove {
                    engine.rotate()
                } else if ty > 30 && flick > 120 {
                    engine.hardDrop()
                }
                processedX = 0
                processedY = 0
                didMove = false
            }
    }
}
