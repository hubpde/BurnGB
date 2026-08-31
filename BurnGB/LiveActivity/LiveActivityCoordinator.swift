//
//  LiveActivityCoordinator.swift
//  BurnGB
//
//  官方 ActivityKit 实时活动协调器。
//

import Foundation
import ActivityKit
import BurnGBCore

/// 串行管理一个 BurnGB 实时活动，避免更新乱序和任务积压。
@MainActor
final class LiveActivityCoordinator {
    private var activity: Activity<BurnActivityAttributes>?
    private var queuedSnapshot: TrafficSnapshot?
    private var updateTask: Task<Void, Never>?
    private var tokenTask: Task<Void, Never>?
    private var stateTask: Task<Void, Never>?
    private var generation = UUID()

    private let tokenDefaults = UserDefaults(suiteName: BurnCheckpointStore.appGroupIdentifier)

    deinit {
        updateTask?.cancel()
        tokenTask?.cancel()
        stateTask?.cancel()
    }

    /// App 启动时接管仍然存在的实时活动，清理多余旧实例。
    func restoreExistingActivity() {
        let activities = Activity<BurnActivityAttributes>.activities
        guard let newest = activities.last else { return }

        activity = newest
        for oldActivity in activities.dropLast() {
            Task { @MainActor in
                await oldActivity.end(nil, dismissalPolicy: .immediate)
            }
        }
        observeActivity()
        observePushToken()
    }

    /// 前台点火后申请带 push token 的实时活动。
    func start(for snapshot: TrafficSnapshot) async {
        await endCurrent()
        guard let runID = snapshot.runID else { return }

        let attributes = BurnActivityAttributes(
            nodeName: snapshot.nodeName,
            quotaBytes: snapshot.quotaBytes
        )
        let state = makeState(snapshot: snapshot, runID: runID)

        do {
            // token 模式为未来 ActivityKit APNs 进程外更新预留能力。
            let requested = try Activity.request(
                attributes: attributes,
                content: ActivityContent(
                    state: state,
                    staleDate: Date().addingTimeInterval(15)
                ),
                pushType: .token
            )
            activity = requested
            generation = UUID()
            observeActivity()
            observePushToken()
        } catch {
            print("[LiveActivityCoordinator] 实时活动申请失败：\(error.localizedDescription)")
        }
    }

    /// 将最新快照放入队列；同一时间最多只有一个 update Task。
    func update(with snapshot: TrafficSnapshot) {
        guard activity != nil, snapshot.runID != nil else { return }
        queuedSnapshot = snapshot
        guard updateTask == nil else { return }

        let currentGeneration = generation
        updateTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self,
                      self.generation == currentGeneration,
                      let nextSnapshot = self.queuedSnapshot,
                      let currentActivity = self.activity,
                      let runID = nextSnapshot.runID else {
                    break
                }

                self.queuedSnapshot = nil
                let state = self.makeState(snapshot: nextSnapshot, runID: runID)
                await currentActivity.update(
                    ActivityContent(
                        state: state,
                        staleDate: Date().addingTimeInterval(15)
                    )
                )
            }
            self?.updateTask = nil
        }
    }

    /// 立即结束活动并取消所有待处理更新。
    func endCurrent() async {
        let pendingUpdateTask = updateTask
        pendingUpdateTask?.cancel()
        updateTask = nil
        queuedSnapshot = nil
        tokenTask?.cancel()
        tokenTask = nil
        stateTask?.cancel()
        stateTask = nil
        await pendingUpdateTask?.value

        if let currentActivity = activity {
            activity = nil
            generation = UUID()
            await currentActivity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private func observeActivity() {
        guard let currentActivity = activity else { return }
        let observedID = currentActivity.id
        stateTask?.cancel()
        stateTask = Task { @MainActor [weak self] in
            for await state in currentActivity.activityStateUpdates {
                guard !Task.isCancelled else { return }
                if state == .ended || state == .dismissed {
                    if self?.activity?.id == observedID {
                        self?.activity = nil
                    }
                    return
                }
            }
        }
    }

    private func observePushToken() {
        guard let currentActivity = activity else { return }
        tokenTask?.cancel()
        tokenTask = Task { @MainActor [weak self] in
            for await token in currentActivity.pushTokenUpdates {
                guard !Task.isCancelled else { return }
                let value = token.map { String(format: "%02x", $0) }.joined()
                self?.tokenDefaults?.set(value, forKey: "burngb.activity.push-token")
            }
        }
    }

    private func makeState(snapshot: TrafficSnapshot, runID: RunID) -> BurnActivityAttributes.ContentState {
        BurnActivityAttributes.ContentState(
            runID: runID.description,
            startedAt: snapshot.startedAt ?? Date(),
            lastUpdatedAt: snapshot.lastUpdatedAt,
            totalBytes: snapshot.totalBytes,
            speedBytesPerSecond: snapshot.speedBytesPerSecond,
            quotaBytes: snapshot.quotaBytes,
            activeWorkers: snapshot.activeWorkerCount,
            phase: snapshot.phase,
            backgroundState: snapshot.backgroundState
        )
    }
}
