//
//  MotionTiltController.swift
//  2048fortest
//
//  Created by Codex on 2026/1/7.
//

import Foundation
import CoreMotion

final class MotionTiltController: ObservableObject {
    private let motionManager = CMMotionManager()
    private var lastTriggerDate: Date = .distantPast
    private var isReleased: Bool = true
    private var filteredGravity: (x: Double, y: Double) = (0, 0)
    private var filterInitialized = false

    /// High threshold (g) to fire on dominant axis.
    var highThreshold: Double = 0.22
    /// Low threshold (g) to re-arm after returning to neutral.
    var lowThreshold: Double = 0.08
    /// Minimum time between triggers.
    var cooldown: TimeInterval = 0.25
    /// Low-pass filter factor for gravity (0-1, higher = more responsive).
    var filterAlpha: Double = 0.45
    var invertPitch: Bool = false
    var invertRoll: Bool = false

    /// Emits a direction when tilt is detected.
    var onDirection: ((MoveDirection) -> Void)?

    @Published var statusText: String = "Motion idle"
    @Published var lastDirectionText: String = "尚未触发"

    func start() {
        guard motionManager.isDeviceMotionAvailable else {
            statusText = "Motion not available"
            return
        }

        lastTriggerDate = .distantPast
        isReleased = true
        filterInitialized = false
        motionManager.deviceMotionUpdateInterval = 0.015 // more responsive
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self else { return }
            self.handleMotion(motion)
        }
        statusText = "Motion active"
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
        statusText = "Motion stopped"
    }

    private func handleMotion(_ motion: CMDeviceMotion?) {
        guard let motion else { return }

        // 使用重力向量投影，带简单低通滤波，减少抖动
        var axisY = motion.gravity.y // 对应 pitch-ish
        var axisX = motion.gravity.x // 对应 roll-ish

        if invertPitch { axisY *= -1 }
        if invertRoll { axisX *= -1 }

        if !filterInitialized {
            filteredGravity = (axisX, axisY)
            filterInitialized = true
        } else {
            filteredGravity = (
                x: filteredGravity.x * (1 - filterAlpha) + axisX * filterAlpha,
                y: filteredGravity.y * (1 - filterAlpha) + axisY * filterAlpha
            )
        }

        let absY = abs(filteredGravity.y)
        let absX = abs(filteredGravity.x)

        // 如果未回到中性区则先等待，防止反向回摆触发
        if isReleased == false {
            if absY < lowThreshold && absX < lowThreshold {
                isReleased = true
                statusText = "Motion active · Ready"
            } else {
                statusText = "Motion active · Waiting neutral"
                return
            }
        }

        // 如果冷却未过，也不触发
        let now = Date()
        guard now.timeIntervalSince(lastTriggerDate) >= cooldown else {
            statusText = "Motion active · Cooling"
            return
        }

        guard absY >= highThreshold || absX >= highThreshold else {
            statusText = "Motion active · Ready"
            return
        }

        // 只选主轴，避免斜向双触发
        let chosenDirection: MoveDirection
        if absY >= absX {
            chosenDirection = filteredGravity.y > 0 ? .down : .up
        } else {
            chosenDirection = filteredGravity.x > 0 ? .right : .left
        }

        lastTriggerDate = now
        isReleased = false
        statusText = "Motion active · Cooling"

        onDirection?(chosenDirection)
        lastDirectionText = directionDescription(chosenDirection)
    }

    private func directionDescription(_ direction: MoveDirection) -> String {
        switch direction {
        case .up: return "上"
        case .down: return "下"
        case .left: return "左"
        case .right: return "右"
        }
    }
}
