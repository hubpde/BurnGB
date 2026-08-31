//
//  BurnActivityAttributes.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import Foundation
#if canImport(ActivityKit)
import ActivityKit

/// 灵动岛（Dynamic Island）与实时活动（Live Activity）共享数据契约
public struct BurnActivityAttributes: ActivityAttributes {
    /// 动态变化的状态载荷
    public struct ContentState: Codable, Hashable {
        /// 当前瞬时速率（Byte/s）
        public var currentSpeedBytesPerSec: Double
        /// 累计已消耗字节数
        public var totalBurnedBytes: Int64
        /// 定量目标进度百分比（0.0 ~ 1.0）
        public var progress: Double
        /// 引擎运行状态
        public var isRunning: Bool
        /// 是否处于暂停状态
        public var isPaused: Bool
        /// 当前活跃并发线程数
        public var activeThreads: Int
        /// 运行已持续秒数
        public var elapsedSeconds: Int
        /// 格式化后的速率文本（如 "124.5 MB/s"）
        public var formattedSpeed: String
        /// 格式化后的消耗总量文本（如 "8.20 GB"）
        public var formattedBurned: String
        /// 格式化后的带宽文本（如 "996.0 Mbps"）
        public var formattedBitrate: String

        public init(
            currentSpeedBytesPerSec: Double,
            totalBurnedBytes: Int64,
            progress: Double = 0.0,
            isRunning: Bool = true,
            isPaused: Bool = false,
            activeThreads: Int = 8,
            elapsedSeconds: Int = 0,
            formattedSpeed: String = "0.0 MB/s",
            formattedBurned: String = "0.0 MB",
            formattedBitrate: String = "0.0 Mbps"
        ) {
            self.currentSpeedBytesPerSec = currentSpeedBytesPerSec
            self.totalBurnedBytes = totalBurnedBytes
            self.progress = progress
            self.isRunning = isRunning
            self.isPaused = isPaused
            self.activeThreads = activeThreads
            self.elapsedSeconds = elapsedSeconds
            self.formattedSpeed = formattedSpeed
            self.formattedBurned = formattedBurned
            self.formattedBitrate = formattedBitrate
        }
    }

    // MARK: - 静态不可变属性
    /// 当前连接的节点名称
    public var nodeName: String
    /// 设定的定量上限总字节数（可选）
    public var targetQuotaBytes: Int64?
    /// 格式化后的定量上限文本（如 "10.00 GB"）
    public var formattedQuota: String?

    public init(
        nodeName: String,
        targetQuotaBytes: Int64? = nil,
        formattedQuota: String? = nil
    ) {
        self.nodeName = nodeName
        self.targetQuotaBytes = targetQuotaBytes
        self.formattedQuota = formattedQuota
    }
}
#endif
