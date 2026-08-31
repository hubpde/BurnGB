//
//  ContinuedProcessingCoordinator.swift
//  BurnGB
//
//  iOS 26 BGContinuedProcessingTask 适配层。
//

import Foundation
import BackgroundTasks
import BurnGBCore

/// 管理由用户在前台明确发起的 iOS 26 持续处理任务。
/// 系统可以排队、拒绝、过期或终止任务，因此这里始终把真实状态反馈给引擎。
@MainActor
final class ContinuedProcessingCoordinator {
    private let engine: TrafficEngine
    private var monitoringTask: Task<Void, Never>?
    private var requestIsPending = false

    init(engine: TrafficEngine) {
        self.engine = engine
    }

    /// 将系统回调安装到 AppDelegate。
    func install(on appDelegate: AppDelegate) {
        appDelegate.installContinuedTaskHandler { [weak self] task in
            self?.handle(task)
        }
    }

    /// 前台用户点击开始后提交持续处理请求。
    func submitIfNeeded(for configuration: BurnConfiguration) async throws {
        guard configuration.requestsBackgroundContinuation else { return }
        guard #available(iOS 26.0, *) else { return }
        guard !requestIsPending, monitoringTask == nil else { return }

        let request = BGContinuedProcessingTaskRequest(
            identifier: AppDelegate.continuedProcessingIdentifier,
            title: "BurnGB 正在消耗流量",
            subtitle: "系统将尽力在后台继续执行"
        )
        // 资源暂不可用时排队，而不是让用户点击开始后直接失去后台机会。
        request.strategy = .queue

        do {
            try BGTaskScheduler.shared.submit(request)
            requestIsPending = true
            await engine.setBackgroundState(.waitingForSystem)
        } catch {
            requestIsPending = false
            await engine.setBackgroundState(.unavailable)
            throw TrafficEngineError.backgroundSubmissionFailed(error.localizedDescription)
        }
    }

    /// 处理系统实际开始执行的任务。
    private func handle(_ task: BGContinuedProcessingTask) {
        requestIsPending = false
        monitoringTask?.cancel()

        task.expirationHandler = { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                await self.engine.setBackgroundState(.expired)
                await self.engine.pause()
                self.monitoringTask?.cancel()
            }
        }

        monitoringTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.monitoringTask = nil }
            await self.engine.setBackgroundState(.running)
            task.progress.totalUnitCount = 100

            var completed = false
            while !Task.isCancelled {
                let snapshot = await self.engine.snapshot()
                let isActive = snapshot.phase == .running || snapshot.phase == .paused || snapshot.phase == .starting
                guard isActive else {
                    completed = snapshot.phase == .completed || snapshot.phase == .idle
                    break
                }

                if let quota = snapshot.quotaBytes, quota > 0 {
                    let ratio = min(max(Double(snapshot.totalBytes) / Double(quota), 0), 1)
                    task.progress.completedUnitCount = Int64(ratio * 100)
                }

                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }

            guard !Task.isCancelled else {
                task.setTaskCompleted(success: false)
                return
            }
            task.setTaskCompleted(success: completed)
        }
    }

    /// 用户主动终止时停止监控，不再提交新的后台请求。
    func cancel() {
        requestIsPending = false
        monitoringTask?.cancel()
        monitoringTask = nil
    }
}
