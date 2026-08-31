//
//  BurnActivityAttributes.swift
//  BurnGBCore
//
//  App 与 Widget 共享的 ActivityKit 数据契约。
//

import Foundation
@preconcurrency import ActivityKit

/// BurnGB 灵动岛与锁屏实时活动的数据模型。
/// 只传递原始事实数据，格式化、动态字体与过期状态由 Widget 完成。
public struct BurnActivityAttributes: ActivityAttributes, Sendable {
    /// 实时活动中会不断变化的状态。
    public struct ContentState: Codable, Hashable, Sendable {
        /// 当前任务 ID，用来避免旧任务的状态覆盖新任务。
        public var runID: String
        /// 任务开始的墙上时间，用于 Widget 派生运行时长。
        public var startedAt: Date
        /// 最近一次可靠更新的墙上时间。
        public var lastUpdatedAt: Date
        /// 已计入配额的应用层字节数。
        public var totalBytes: Int64
        /// 最近一个采样窗口的应用层接收速率（Byte/s）。
        public var speedBytesPerSecond: Double
        /// 定量目标；nil 代表不设上限。
        public var quotaBytes: Int64?
        /// 当前配置的并发 worker 数。
        public var activeWorkers: Int
        /// 当前任务阶段。
        public var phase: BurnPhase
        /// 后台执行的系统状态。
        public var backgroundState: BackgroundExecutionState

        public init(
            runID: String,
            startedAt: Date,
            lastUpdatedAt: Date = Date(),
            totalBytes: Int64,
            speedBytesPerSecond: Double,
            quotaBytes: Int64?,
            activeWorkers: Int,
            phase: BurnPhase,
            backgroundState: BackgroundExecutionState
        ) {
            self.runID = runID
            self.startedAt = startedAt
            self.lastUpdatedAt = lastUpdatedAt
            self.totalBytes = max(totalBytes, 0)
            self.speedBytesPerSecond = speedBytesPerSecond.isFinite ? max(speedBytesPerSecond, 0) : 0
            self.quotaBytes = quotaBytes
            self.activeWorkers = max(activeWorkers, 0)
            self.phase = phase
            self.backgroundState = backgroundState
        }
    }

    /// 实时活动创建后不会变化的属性。
    public var nodeName: String
    /// 创建活动时的配额快照。
    public var quotaBytes: Int64?

    public init(nodeName: String, quotaBytes: Int64?) {
        self.nodeName = nodeName
        self.quotaBytes = quotaBytes
    }
}
