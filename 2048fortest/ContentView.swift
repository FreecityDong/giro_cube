import SwiftUI
import SceneKit

struct ContentView: View {
    @StateObject private var motion = MotionOrientationViewModel()

    var body: some View {
        VStack(spacing: 16) {
            header

            CubeSceneView(motion: motion)
                .frame(height: 360)
                .cornerRadius(16)

            controls

            motionReadout
        }
        .padding()
        .onAppear { motion.start() }
        .onDisappear { motion.stop() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Gyro Cube")
                    .font(.largeTitle.bold())
                Text("用陀螺仪控制 3D 立方体视角")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: motion.recenter) {
                Label("重新校准", systemImage: "scope")
            }
            .buttonStyle(.bordered)
        }
    }

    private var controls: some View {
        HStack {
            Button(action: { motion.start() }) {
                Label("启动", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)

            Button(action: { motion.stop() }) {
                Label("停止", systemImage: "stop.fill")
            }
            .buttonStyle(.bordered)

            Spacer()

            Text(motion.status)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var motionReadout: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("实时陀螺仪（相对校准基准）")
                .font(.headline)
            HStack {
                dataBox(title: "Roll", value: motion.roll.toDegrees(), unit: "°")
                dataBox(title: "Pitch", value: motion.pitch.toDegrees(), unit: "°")
                dataBox(title: "Yaw", value: motion.yaw.toDegrees(), unit: "°")
            }
            HStack {
                dataBox(title: "Quat x", value: motion.quaternion.x, unit: "")
                dataBox(title: "Quat y", value: motion.quaternion.y, unit: "")
                dataBox(title: "Quat z", value: motion.quaternion.z, unit: "")
                dataBox(title: "Quat w", value: motion.quaternion.w, unit: "")
            }
        }
    }

    private func dataBox(title: String, value: Double, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(String(format: "%.2f%@", value, unit))
                .font(.body.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
    }
}

private struct CubeSceneView: View {
    @ObservedObject var motion: MotionOrientationViewModel

    @State private var scene = SCNScene()
    @State private var cubeNode = SCNNode()
    @State private var cameraNode = SCNNode()
    @State private var lightNode = SCNNode()

    var body: some View {
        // 屏蔽触摸旋转，仅陀螺仪控制
        SceneView(scene: scene, pointOfView: cameraNode, options: [])
            .onAppear(perform: setupScene)
            .onChange(of: motion.quaternion) { newValue in
                updateOrientation(with: newValue)
            }
    }

    private func setupScene() {
        scene.background.contents = UIColor.systemBackground

        let box = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.04)
        box.materials = [
            CubeSceneView.material(color: .systemRed),
            CubeSceneView.material(color: .systemBlue),
            CubeSceneView.material(color: .systemGreen),
            CubeSceneView.material(color: .systemOrange),
            CubeSceneView.material(color: .systemPurple),
            CubeSceneView.material(color: .systemTeal)
        ]
        cubeNode.geometry = box
        scene.rootNode.addChildNode(cubeNode)

        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 3.0)
        scene.rootNode.addChildNode(cameraNode)

        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(2, 2, 3)
        scene.rootNode.addChildNode(lightNode)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.color = UIColor(white: 0.4, alpha: 1)
        scene.rootNode.addChildNode(ambient)
    }

    private func updateOrientation(with q: QuaternionData) {
        let quat = SCNQuaternion(Float(q.x), Float(q.y), Float(q.z), Float(q.w))
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.08
        cubeNode.orientation = quat
        SCNTransaction.commit()
    }

    private static func material(color: UIColor) -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = color
        m.locksAmbientWithDiffuse = true
        return m
    }
}

private extension Double {
    func toDegrees() -> Double {
        self * 180 / .pi
    }
}

#Preview {
    ContentView()
}
