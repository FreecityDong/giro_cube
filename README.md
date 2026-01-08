# Gyro Cube（SwiftUI + SceneKit + CoreMotion）

一个简单的陀螺仪演示：用 iPhone 的姿态控制 3D 彩色立方体的旋转，并实时显示姿态（Roll/Pitch/Yaw）和四元数。仅依赖系统框架（SwiftUI/SceneKit/CoreMotion），无第三方库。

## 功能
- 立方体姿态与设备姿态同步，默认以当前姿态为参考的相对量。
- 启动/停止采样按钮，重新校准按钮（将当前姿态设为 0 姿态）。
- 实时数据显示：Roll/Pitch/Yaw（角度）与四元数。
- 触摸旋转已禁用，立方体仅由陀螺仪驱动。

## 运行环境
- iOS 真机（陀螺仪必须可用），SwiftUI + SceneKit，Xcode 15+。
- 工程路径：`2048fortest/`（已重写为 Gyro Cube）。

## 关键文件
- `2048fortest/ContentView.swift`：UI 与 SceneKit 立方体展示，绑定陀螺仪数据。
- `2048fortest/MotionOrientationViewModel.swift`：CoreMotion 封装，输出姿态和四元数，支持校准。
- `2048fortest/_048fortestApp.swift`：App 入口。

## 构建步骤（真机）
1. Xcode 打开 `2048fortest.xcodeproj`，目标选择你的 iPhone。
2. Signing：在 Target > Signing & Capabilities 选择你的 Team，Bundle ID 如有冲突改成唯一的（例如 `com.yourname.gyrocube`）。
3. 权限：Info.plist 已自动生成 `NSMotionUsageDescription = 用于通过设备倾斜控制游戏/演示`（若未生效，手动添加该键值）。
4. `Cmd+R` 运行到设备，首次会提示“运动与健身”权限，需允许。

## 使用说明
- 打开 App 后点击“启动”开始采样，立方体随设备姿态旋转。
- 点击“重新校准”将当前姿态设为零点，后续显示的角度/四元数会基于此参考。
- 点击“停止”暂停采样。
- 底部卡片实时显示 Roll/Pitch/Yaw（单位°）和四元数（x/y/z/w）。

## 可调参数
位于 `MotionOrientationViewModel`：
- `updateInterval`：采样间隔（默认 0.015s），数值越小刷新越快。
- `invertPitch / invertRoll / invertYaw`：若方向相反，可将对应布尔置为 `true`。

## 触摸控制
- 已移除 SceneView 的 `.allowsCameraControl`，用户无法通过手势旋转，所有姿态仅由陀螺仪驱动。

## 常见问题
- **未响应 / 没数据**：确认已允许运动权限、真机解锁且支持陀螺仪。
- **方向感觉相反**：在 `MotionOrientationViewModel` 中调整 `invertPitch/Roll/Yaw`。
- **签名报错**：确保选择了 Team，Bundle ID 唯一；必要时在设备“设置 > 通用 > VPN 与设备管理”信任开发者证书。
