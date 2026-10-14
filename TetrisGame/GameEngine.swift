import SwiftUI
import UIKit
import AudioToolbox
import Combine

final class GameEngine: ObservableObject {
    static let cols = 12
    static let rows = 20

    enum State { case playing, paused, gameOver }

    @Published private(set) var board: [[Tetromino?]] = GameEngine.emptyBoard()
    @Published private(set) var current: Piece?
    @Published private(set) var next: Tetromino = .i
    @Published private(set) var score = 0
    @Published private(set) var lines = 0
    @Published private(set) var best: Int
    @Published private(set) var state: State = .playing

    @Published var soundOn: Bool {
        didSet { UserDefaults.standard.set(soundOn, forKey: "sound") }
    }
    @Published var vibrationOn: Bool {
        didSet { UserDefaults.standard.set(vibrationOn, forKey: "vibration") }
    }

    var level: Int { lines / 10 + 1 }
    var isNewBest: Bool { score > 0 && score >= best }

    private var bag: [Tetromino] = []
    private var timer: Timer?

    init() {
        let d = UserDefaults.standard
        best = d.integer(forKey: "best")
        soundOn = d.object(forKey: "sound") as? Bool ?? true
        vibrationOn = d.object(forKey: "vibration") as? Bool ?? true
        startNewGame()
    }

    deinit { timer?.invalidate() }

    // MARK: - Lifecycle

    static func emptyBoard() -> [[Tetromino?]] {
        Array(repeating: Array<Tetromino?>(repeating: nil, count: cols), count: rows)
    }

    func startNewGame() {
        stopTimer()
        board = GameEngine.emptyBoard()
        score = 0
        lines = 0
        bag.removeAll()
        next = drawFromBag()
        state = .playing
        spawn()
        if state == .playing { startTimer() }
    }

    func pause() {
        guard state == .playing else { return }
        state = .paused
        stopTimer()
    }

    func resume() {
        guard state == .paused else { return }
        state = .playing
        startTimer()
    }

    func shutdown() { stopTimer() }

    // MARK: - Player actions

    func moveLeft() {
        if tryMove(dx: -1, dy: 0) { playSound(1104) }
    }

    func moveRight() {
        if tryMove(dx: 1, dy: 0) { playSound(1104) }
    }

    /// Moves one row down (does not lock; gravity handles locking).
    func softDrop() {
        if tryMove(dx: 0, dy: 1) { score += 1 }
    }

    func hardDrop() {
        guard state == .playing, var p = current else { return }
        var distance = 0
        while true {
            var q = p
            q.y += 1
            if isValid(q) { p = q; distance += 1 } else { break }
        }
        current = p
        score += distance * 2
        haptic(.medium)
        lockPiece()
    }

    func rotate() {
        guard state == .playing, var p = current, p.type != .o else { return }
        p.rotation = (p.rotation + 1) % 4
        for kick in [0, -1, 1, -2, 2] {
            var q = p
            q.x += kick
            if isValid(q) {
                current = q
                playSound(1104)
                haptic(.light)
                return
            }
        }
    }

    // MARK: - Ghost piece

    var ghostCells: [(x: Int, y: Int)] {
        guard let p = current else { return [] }
        var g = p
        while true {
            var q = g
            q.y += 1
            if isValid(q) { g = q } else { break }
        }
        return g.cells
    }

    // MARK: - Internals

    private func drawFromBag() -> Tetromino {
        if bag.isEmpty { bag = Tetromino.allCases.shuffled() }
        return bag.removeLast()
    }

    private func spawn() {
        let type = next
        next = drawFromBag()
        let p = Piece(type: type, rotation: 0, x: (GameEngine.cols - type.size) / 2, y: 0)
        current = p
        if !isValid(p) { endGame() }
    }

    private func isValid(_ p: Piece) -> Bool {
        for c in p.cells {
            if c.x < 0 || c.x >= GameEngine.cols || c.y >= GameEngine.rows { return false }
            if c.y >= 0 && board[c.y][c.x] != nil { return false }
        }
        return true
    }

    @discardableResult
    private func tryMove(dx: Int, dy: Int) -> Bool {
        guard state == .playing, var p = current else { return false }
        p.x += dx
        p.y += dy
        if isValid(p) {
            current = p
            return true
        }
        return false
    }

    private func lockPiece() {
        guard let p = current else { return }
        for c in p.cells {
            if c.y < 0 { endGame(); return }
            board[c.y][c.x] = p.type
        }
        current = nil

        let levelBefore = level
        let cleared = clearLines()
        if cleared > 0 {
            score += [0, 100, 300, 500, 800][min(cleared, 4)] * levelBefore
            lines += cleared
            playSound(1057)
            haptic(.heavy)
        } else {
            playSound(1105)
            haptic(.light)
        }
        saveBestIfNeeded()

        spawn()
        if state == .playing && level != levelBefore { startTimer() }
    }

    private func clearLines() -> Int {
        let remaining = board.filter { row in row.contains(where: { $0 == nil }) }
        let cleared = GameEngine.rows - remaining.count
        if cleared > 0 {
            let empty = Array(repeating: Array<Tetromino?>(repeating: nil, count: GameEngine.cols), count: cleared)
            board = empty + remaining
        }
        return cleared
    }

    private func endGame() {
        stopTimer()
        state = .gameOver
        saveBestIfNeeded()
        playSound(1073)
        haptic(.heavy)
    }

    private func saveBestIfNeeded() {
        if score > best {
            best = score
            UserDefaults.standard.set(best, forKey: "best")
        }
    }

    // MARK: - Timer

    private func startTimer() {
        stopTimer()
        let interval = max(0.08, 0.8 * pow(0.85, Double(level - 1)))
        let t = Timer(timeInterval: interval, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard state == .playing else { return }
        if !tryMove(dx: 0, dy: 1) { lockPiece() }
    }

    // MARK: - Feedback

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard vibrationOn else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    /// System sounds as placeholders — replace with bundled audio (AVAudioPlayer) for custom effects.
    private func playSound(_ id: SystemSoundID) {
        guard soundOn else { return }
        AudioServicesPlaySystemSound(id)
    }
}
