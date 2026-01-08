//
//  Game2048.swift
//  2048fortest
//
//  Created by Codex on 2026/1/7.
//

import Foundation

enum MoveDirection {
    case up, down, left, right
}

/// Pure 2048 game logic. No UI dependencies.
struct Game2048 {
    private(set) var board: [[Int]]
    private(set) var score: Int = 0
    private(set) var isGameOver: Bool = false

    let size = 4

    init() {
        board = Array(repeating: Array(repeating: 0, count: size), count: size)
        newGame()
    }

    mutating func newGame() {
        score = 0
        board = Array(repeating: Array(repeating: 0, count: size), count: size)
        isGameOver = false
        spawnRandomTile()
        spawnRandomTile()
    }

    /// Attempts to move the board in a direction. Returns true if the board changed.
    @discardableResult
    mutating func move(_ direction: MoveDirection) -> Bool {
        guard !isGameOver else { return false }

        var moved = false
        var gainedScore = 0

        switch direction {
        case .left:
            for row in 0..<size {
                let (newRow, didMove, rowScore) = merge(line: board[row])
                board[row] = newRow
                moved = moved || didMove
                gainedScore += rowScore
            }
        case .right:
            for row in 0..<size {
                let reversed = board[row].reversed()
                let (merged, didMove, rowScore) = merge(line: Array(reversed))
                board[row] = Array(merged.reversed())
                moved = moved || didMove
                gainedScore += rowScore
            }
        case .up:
            for col in 0..<size {
                let column = (0..<size).map { board[$0][col] }
                let (merged, didMove, colScore) = merge(line: column)
                for row in 0..<size {
                    board[row][col] = merged[row]
                }
                moved = moved || didMove
                gainedScore += colScore
            }
        case .down:
            for col in 0..<size {
                let column = (0..<size).map { board[$0][col] }.reversed()
                let (merged, didMove, colScore) = merge(line: Array(column))
                for (index, value) in merged.enumerated() {
                    board[size - 1 - index][col] = value
                }
                moved = moved || didMove
                gainedScore += colScore
            }
        }

        if moved {
            score += gainedScore
            spawnRandomTile()
            isGameOver = !hasMovesAvailable()
        }

        return moved
    }

    /// Compresses + merges a single line leftwards. Each tile merges once per move.
    /// - Returns: (newLine, didMove, gainedScore)
    private func merge(line: [Int]) -> ([Int], Bool, Int) {
        var filtered = line.filter { $0 != 0 } // remove zeros
        var mergedLine: [Int] = []
        var gainedScore = 0

        var index = 0
        while index < filtered.count {
            if index + 1 < filtered.count && filtered[index] == filtered[index + 1] {
                let newValue = filtered[index] * 2
                mergedLine.append(newValue)
                gainedScore += newValue
                index += 2 // skip the merged pair
            } else {
                mergedLine.append(filtered[index])
                index += 1
            }
        }

        while mergedLine.count < size {
            mergedLine.append(0)
        }

        let didMove = mergedLine != line
        return (mergedLine, didMove, gainedScore)
    }

    private mutating func spawnRandomTile() {
        let emptyPositions = emptyTiles()
        guard !emptyPositions.isEmpty else { return }

        let chosenIndex = Int.random(in: 0..<emptyPositions.count)
        let position = emptyPositions[chosenIndex]
        let value = Double.random(in: 0...1) < 0.9 ? 2 : 4
        board[position.0][position.1] = value
    }

    private func emptyTiles() -> [(Int, Int)] {
        var positions: [(Int, Int)] = []
        for row in 0..<size {
            for col in 0..<size {
                if board[row][col] == 0 {
                    positions.append((row, col))
                }
            }
        }
        return positions
    }

    private func hasMovesAvailable() -> Bool {
        if !emptyTiles().isEmpty { return true }

        // check adjacent equals
        for row in 0..<size {
            for col in 0..<size {
                let value = board[row][col]
                if (row + 1 < size && board[row + 1][col] == value) ||
                    (col + 1 < size && board[row][col + 1] == value) {
                    return true
                }
            }
        }

        return false
    }
}
