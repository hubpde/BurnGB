//
//  LiveActivityManager.swift
//  BurnGB
//
//  Created for BurnGB - iOS Native Edition.
//

import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

/// 官方实时活动（Live Activity）与灵动岛（Dynamic Island）生命周期管理器
/// 遵循 iOS 官方 ActivityKit 规范，利用 Frequent Updates（高频更新）机制
/// 在前后台持续向系统灵动岛和锁屏推送实时网速、进度与用量数据
public final class LiveActivityManager {
    public static let shared = LiveActivityManager()

    #if canImport(ActivityKit)
    /// 当前活跃的系统实时活动实例
    private var currentActivity: Activity<BurnActivityAttributes>?
    #endif

    private init() {}

    /// 请求并开启官方实时活动（在灵动岛与锁屏显示）
    /// - Parameters:
    ///   - nodeName: 当前测速节点名称
    ///   - targetQuotaBytes: 定量目标字节数（可选）
    ///   - formattedQuota: 格式化后的目标文本（如 "10.00 GB"）
    public func startActivity(
        nodeName: String,
        targetQuotaBytes: Int64?,
        formattedQuota: String?
    ) {
        #if canImport(ActivityKit)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("[LiveActivityManager] 用户未开启实时活动权限")
            return
        }

        // 停止之前的活动实例，保证仅存在一个唯一的活跃实时活动
        endActivity()

        // 构建不可变的静态属性
        let attributes = BurnActivityAttributes(
            nodeName: nodeName,
            targetQuotaBytes: targetQuotaBytes,
            formattedQuota: formattedQuota
        )

        // 初始状态数据
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
            // 向系统申请实时活动展示
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            self.currentActivity = activity
            print("[LiveActivityManager] 实时活动启动成功 ID: \(activity.id)")
        } catch {
            print("[LiveActivityManager] 实时活动启动失败: \(error.localizedDescription)")
        }
        #endif
    }

    /// 高频更新灵动岛与锁屏实时活动状态
    /// - Parameters:
    ///   - currentSpeed: 瞬时速率（Byte/s）
    ///   - totalBurned: 累计已消耗字节数
    ///   - targetQuota: 定量上限（可选）
    ///   - isRunning: 是否在运行中
    ///   - isPaused: 是否处于暂停
    ///   - activeThreads: 并发线程数
    ///   - elapsedSeconds: 持续秒数
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

        // 计算定量完成百分比
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
            // 设置 5 秒后过期，触发系统平滑插值
            let staleDate = Date().addingTimeInterval(5)
            await activity.update(.init(state: updatedState, staleDate: staleDate))
        }
        #endif
    }

    /// 立即结束并关闭灵动岛实时活动
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
