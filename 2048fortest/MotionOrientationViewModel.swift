//
//  MotionOrientationViewModel.swift
//  2048fortest
//
//  Created by Codex on 2026/1/08.
//

import Foundation
import CoreMotion

struct QuaternionData: Equatable {
    var x: Double
    var y: Double
    var z: Double
    var w: Double
}

final class MotionOrientationViewModel: ObservableObject {
    private let motionManager = CMMotionManager()
    private var referenceAttitude: CMAttitude?

    @Published var roll: Double = 0
    @Published var pitch: Double = 0
    @Published var yaw: Double = 0
    @Published var quaternion: QuaternionData = .init(x: 0, y: 0, z: 0, w: 1)
    @Published var status: String = "未启动"

    var updateInterval: TimeInterval = 0.015
    var invertPitch: Bool = false
    var invertRoll: Bool = false
    var invertYaw: Bool = false

    func start() {
        guard motionManager.isDeviceMotionAvailable else {
            status = "设备不支持 Motion"
            return
        }
        motionManager.deviceMotionUpdateInterval = updateInterval
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.handle(motion.attitude)
        }
        status = "运行中"
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
        status = "已停止"
    }

    func recenter() {
        if let att = motionManager.deviceMotion?.attitude {
            referenceAttitude = att
        }
    }

    private func handle(_ attitude: CMAttitude) {
        let relative = attitude.copy() as! CMAttitude
        if let ref = referenceAttitude {
            relative.multiply(byInverseOf: ref)
        }

        var p = relative.pitch
        var r = relative.roll
        var y = relative.yaw

        if invertPitch { p *= -1 }
        if invertRoll { r *= -1 }
        if invertYaw { y *= -1 }

        roll = r
        pitch = p
        yaw = y

        let q = relative.quaternion
        quaternion = .init(x: q.x, y: q.y, z: q.z, w: q.w)
        status = "运行中"
    }
}

