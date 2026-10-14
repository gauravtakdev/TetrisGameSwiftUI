import SwiftUI

enum Tetromino: Int, CaseIterable {
    case i = 1, o, t, s, z, j, l

    /// Side length of the square box the piece rotates in.
    var size: Int {
        switch self {
        case .i: return 4
        case .o: return 2
        default: return 3
        }
    }

    /// (x, y) cells in the spawn orientation, inside the rotation box.
    var baseCells: [(Int, Int)] {
        switch self {
        case .i: return [(0, 1), (1, 1), (2, 1), (3, 1)]
        case .o: return [(0, 0), (1, 0), (0, 1), (1, 1)]
        case .t: return [(1, 0), (0, 1), (1, 1), (2, 1)]
        case .s: return [(1, 0), (2, 0), (0, 1), (1, 1)]
        case .z: return [(0, 0), (1, 0), (1, 1), (2, 1)]
        case .j: return [(0, 0), (0, 1), (1, 1), (2, 1)]
        case .l: return [(2, 0), (0, 1), (1, 1), (2, 1)]
        }
    }

    var color: Color {
        switch self {
        case .i: return Color(hex: 0x4FD8EC)
        case .o: return Color(hex: 0xF2D13C)
        case .t: return Color(hex: 0xA77BE8)
        case .s: return Color(hex: 0x6DDBA0)
        case .z: return Color(hex: 0xE85A5A)
        case .j: return Color(hex: 0x4C86E8)
        case .l: return Color(hex: 0xEBA047)
        }
    }
}

struct Piece {
    var type: Tetromino
    var rotation: Int = 0
    var x: Int
    var y: Int

    /// Absolute board cells for the current rotation (clockwise).
    var cells: [(x: Int, y: Int)] {
        let n = type.size
        return type.baseCells.map { base -> (x: Int, y: Int) in
            var c = base
            for _ in 0..<(rotation % 4) {
                c = (n - 1 - c.1, c.0)
            }
            return (x: x + c.0, y: y + c.1)
        }
    }
}
