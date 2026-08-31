//
//  LiveActivityManager.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

/// 灵动岛与锁屏实时活动（Live Activity）生命周期管理器
public final class LiveActivityManager {
    public static let shared = LiveActivityManager()

    #if canImport(ActivityKit)
    /// 当前活跃的 Activity 句柄
    private var currentActivity: Activity<BurnActivityAttributes>?
    #endif

    private init() {}

    /// 请求启动灵动岛与锁屏实时活动
    public func startActivity(
        nodeName: String,
        targetQuotaBytes: Int64?,
        formattedQuota: String?
    ) {
        #if canImport(ActivityKit)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // 先清理可能存在的旧活动实例
        endActivity()

        let attributes = BurnActivityAttributes(
            nodeName: nodeName,
            targetQuotaBytes: targetQuotaBytes,
            formattedQuota: formattedQuota
        )

        let initialSpeed = ByteFormatter.formatFullSpeed(0)
        let initialBurned = ByteFormatter.formatFullBytes(0)
        let initialBitrate = ByteFormatter.formatFullBitrate(0)

        let initialState = BurnActivityAttributes.ContentState(
            currentSpeedBytesPerSec: 0,
            totalBurnedBytes: 0,
            progress: 0.0,
            isRunning: true,
            isPaused: false,
            activeThreads: 8,
            elapsedSeconds: 0,
            formattedSpeed: initialSpeed,
            formattedBurned: initialBurned,
            formattedBitrate: initialBitrate
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            self.currentActivity = activity
        } catch {
            print("[LiveActivityManager] 实时活动启动失败: \(error.localizedDescription)")
        }
        #endif
    }

    /// 高频平滑更新灵动岛与锁屏卡片内容状态
    public func updateActivity(
        currentSpeed: Double,
        totalBurned: Int64,
        targetQuota: Int64?,
        isRunning: Bool,
        isPaused: Bool,
        activeThreads: Int,
        elapsedSeconds: Int
    ) {
        #if canImport(ActivityKit)
        guard let activity = currentActivity else { return }

        var progress: Double = 0.0
        if let quota = targetQuota, quota > 0 {
            progress = min(max(Double(totalBurned) / Double(quota), 0.0), 1.0)
        }

        let speedStr = ByteFormatter.formatFullSpeed(currentSpeed)
        let burnedStr = ByteFormatter.formatFullBytes(totalBurned)
        let bitrateStr = ByteFormatter.formatFullBitrate(currentSpeed)

        let updatedState = BurnActivityAttributes.ContentState(
            currentSpeedBytesPerSec: currentSpeed,
            totalBurnedBytes: totalBurned,
            progress: progress,
            isRunning: isRunning,
            isPaused: isPaused,
            activeThreads: activeThreads,
            elapsedSeconds: elapsedSeconds,
            formattedSpeed: speedStr,
            formattedBurned: burnedStr,
            formattedBitrate: bitrateStr
        )

        Task {
            await activity.update(.init(state: updatedState, staleDate: nil))
        }
        #endif
    }

    /// 立即结束并关闭灵动岛活动
    public func endActivity() {
        #if canImport(ActivityKit)
        guard let activity = currentActivity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        self.currentActivity = nil
        #endif
    }
}
