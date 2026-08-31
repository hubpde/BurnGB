//
//  AppDelegate.swift
//  BurnGB
//
//  iOS 生命周期、后台任务注册与后台 URLSession 事件桥接。
//

import UIKit
import BackgroundTasks

/// UIKit 生命周期桥接器。
/// SwiftUI 负责界面，AppDelegate 负责必须在启动阶段完成的系统注册。
@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate {
    static let continuedProcessingIdentifier = "com.hubpde.BurnGB.continued-processing"

    /// AppModel 安装的持续处理任务回调。
    private var continuedTaskHandler: ((BGContinuedProcessingTask) -> Void)?
    /// 如果系统在 AppModel 注入前唤醒任务，先暂存一次。
    private var pendingContinuedTask: BGContinuedProcessingTask?

    /// 由 AppModel 使用的后台文件下载协调器。
    let backgroundTransferCoordinator = BackgroundTransferCoordinator()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        registerContinuedProcessingTask()
        return true
    }

    /// 注册 iOS 26 用户发起的持续处理任务。
    private func registerContinuedProcessingTask() {
        guard #available(iOS 26.0, *) else { return }

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.continuedProcessingIdentifier,
            using: nil
        ) { [weak self] task in
            guard let continuedTask = task as? BGContinuedProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }

            // BGTaskScheduler 的回调线程由系统决定，统一切回主 actor。
            Task { @MainActor [weak self] in
                self?.deliver(continuedTask)
            }
        }
    }

    /// 将系统任务交给 AppModel/协调器。
    func installContinuedTaskHandler(
        _ handler: @escaping (BGContinuedProcessingTask) -> Void
    ) {
        continuedTaskHandler = handler
        if let pendingContinuedTask {
            self.pendingContinuedTask = nil
            handler(pendingContinuedTask)
        }
    }

    private func deliver(_ task: BGContinuedProcessingTask) {
        if let continuedTaskHandler {
            continuedTaskHandler(task)
        } else {
            pendingContinuedTask = task
        }
    }

    /// 系统在后台 URLSession 需要唤醒 App 时调用。
    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        backgroundTransferCoordinator.receiveBackgroundEvents(
            identifier: identifier,
            completionHandler: completionHandler
        )
    }
}
