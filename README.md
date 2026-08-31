# BurnGB

> 面向 **iOS 26 及以上** 的原生网络流量吞吐工具。

BurnGB 使用 Swift 6、SwiftUI、Swift Concurrency、ActivityKit、BackgroundTasks 和 Swift Charts 编写。界面使用 iOS 26 官方 Liquid Glass API；网络层采用 actor 隔离和精确配额账本；后台执行只使用 Apple 官方系统任务，不使用静音音频保活。

## 功能

- 前台多 worker HTTPS 流式吞吐任务，支持 1～64 个并发 worker。
- 共享 URLSession delegate 数据通道：只读取每个 Data 分块的长度，随后立即释放内容。
- 配额账本在 actor 内原子裁剪，统计不会因为并发分块超过展示上限。
- 基于 `ContinuousClock` 的可取消带宽预约限速。
- 节点搜索、自定义 HTTPS 节点、并发节点延时探测。
- 多出口公网 IP 小探针诊断。
- Swift Charts 吞吐历史与动态字体/辅助功能支持。
- iOS 26 Liquid Glass：`glassEffect`、`GlassEffectContainer`、`.glass` / `.glassProminent` 系统按钮样式。
- ActivityKit 实时活动与 Dynamic Island：compact、minimal、expanded、锁屏和横幅形态。
- App Group checkpoint：应用重启后保留最后可靠的任务状态。
- iOS 26 `BGContinuedProcessingTask`：用户从前台明确开始后，请求系统继续处理网络任务。
- `URLSessionConfiguration.background` + `URLSessionDownloadTask` 有限 Range 片段降级通道。

## 重要的 iOS 系统边界

BurnGB 不会也不能绕过 iOS 的后台策略：

1. **Live Activity 只负责显示，不负责让 App 常驻后台。** `NSSupportsLiveActivitiesFrequentUpdates` 也不是“每秒更新”或后台执行权限。
2. **BGContinuedProcessingTask 是系统管理的 best-effort 长任务。** 它必须由前台用户操作触发，可能排队、提交失败、过期、被系统终止或受资源策略影响。
3. **后台 URLSession 是有限文件下载机制。** 它由系统独立进程调度，必须使用 `URLSessionDownloadTask`，不支持用 DataTask/AsyncBytes 做无限后台流；用户强制退出 App 时系统可能取消任务。
4. **没有官方 API 保证无限期、无间断、固定速率的后台流量消耗。** BurnGB 会在系统允许的窗口内尽最大官方能力继续运行，并在界面和实时活动中显示真实的等待/过期/中断状态。
5. 应用层收到的字节数不等同于运营商最终计费字节，协议开销、压缩、缓存和网络策略都会造成差异。

请只使用自己拥有或明确获授权的 HTTPS 测速端点，并自行承担产生的流量费用。

## 目录

```text
BurnGB/
├── project.yml                         # XcodeGen 工程定义，iOS 26 / Swift 6
├── BurnGB/
│   ├── App/
│   │   ├── BurnGBApp.swift             # SwiftUI 入口与 scenePhase
│   │   ├── AppDelegate.swift            # BGTask 注册和 URLSession 事件桥接
│   │   └── AppModel.swift                # @MainActor @Observable 应用状态
│   ├── Background/
│   │   ├── ContinuedProcessingCoordinator.swift
│   │   └── BackgroundTransferCoordinator.swift
│   ├── LiveActivity/
│   │   └── LiveActivityCoordinator.swift
│   ├── UI/
│   │   ├── RootTabView.swift             # 自适应 Tab/Sidebar 导航
│   │   ├── Dashboard/                    # 主工作台、指标、图表和配置
│   │   ├── Nodes/                        # 节点列表和编辑
│   │   ├── Diagnostics/                  # 出口和节点诊断
│   │   └── Settings/                     # 设置与关于
│   ├── DesignSystem/
│   │   └── BurnTheme.swift               # 官方 Liquid Glass 组件
│   └── Resources/
│       ├── Info.plist
│       ├── BurnGB.entitlements
│       └── PrivacyInfo.xcprivacy
├── BurnGBCore/                           # App/Widget 共享静态 framework 源码
│   ├── Domain/                            # Sendable 任务模型与节点
│   ├── Formatting/                        # 数值格式化
│   ├── Networking/                        # actor 引擎、传输器、账本、限速、探针
│   ├── LiveActivity/                      # ActivityAttributes 数据契约
│   └── Persistence/                       # App Group checkpoint
├── BurnGBWidget/                          # ActivityKit / Dynamic Island 扩展
├── BurnGBTests/                            # Swift/XCTest 核心单元测试
└── .github/workflows/build-ipa.yml        # Xcode 26 CI、测试、归档和 IPA
```

## 构建

Ubuntu 环境不需要也不能运行 Xcode。推送到 GitHub 后，Actions 会在 macOS runner 上：

1. 选择 Xcode 26。
2. 安装固定版本的 XcodeGen。
3. 生成 `BurnGB.xcodeproj`。
4. 使用 Swift 6 strict concurrency 执行单元测试。
5. 归档 iOS device Release 构建。
6. 检查 Widget 扩展是否嵌入到 `BurnGB.app/PlugIns`。
7. 生成并上传 `BurnGB-unsigned-ipa-<run number>` artifact。

工作流默认生成的是**未配置用户 Team/Profile 的 unsigned sideload artifact**，不是 TestFlight/App Store 签名包。要进行正式分发，需要在自己的 Apple Developer Team 下配置 provisioning profile、签名证书和 `exportOptions.plist`。

## ActivityKit 更新说明

App 前台或 `BGContinuedProcessingTask` 获得系统执行时间时，BurnGB 使用本地 `Activity.update` 更新状态。实时活动只传输原始数值、时间和状态，由 Widget 本地格式化，并使用 `context.isStale` 提示数据过期。

项目同时申请 `pushType: .token` 并保存 token，为接入自己的 APNs 服务端预留接口。仓库不包含 APNs 服务端，因此 App 被挂起或终止后不会虚假承诺每秒远程更新。若接入服务端，仍需遵守 ActivityKit 的频繁推送预算和系统节流策略。

## 版本与平台

- 最低部署版本：iOS 26.0 / iPadOS 26.0
- Swift：6.0
- UI：SwiftUI + iOS 26 Liquid Glass
- 实时活动：ActivityKit
- 后台：BGContinuedProcessingTask、Background URLSession（有限分段降级）
- 当前版本暂不提供自定义 App 图标

## 参考

- [Apple：Applying Liquid Glass to custom views](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views)
- [Apple：glassEffect](https://developer.apple.com/documentation/swiftui/view/glasseffect%28_%3Ain%3A%29)
- [Apple：GlassEffectContainer](https://developer.apple.com/documentation/swiftui/glasseffectcontainer)
- [Apple：Displaying live data with Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)
- [Apple：Starting and updating Live Activities with ActivityKit push notifications](https://developer.apple.com/documentation/ActivityKit/starting-and-updating-live-activities-with-activitykit-push-notifications)
- [Apple：Performing long-running tasks on iOS and iPadOS](https://developer.apple.com/documentation/BackgroundTasks/performing-long-running-tasks-on-ios-and-ipados)
- [Apple：Downloading files in the background](https://developer.apple.com/documentation/foundation/downloading-files-in-the-background)
