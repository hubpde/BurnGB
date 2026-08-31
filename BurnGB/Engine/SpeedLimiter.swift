//
//  SpeedLimiter.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import Foundation

/// 基于令牌桶时间窗口算法的带宽平滑限速器
/// 采用 Swift Actor 保证多线程并发调用下的绝对线程安全
public actor SpeedLimiter {
    /// 允许的最高每秒字节数（nil 表示不限速）
    private var maxBytesPerSecond: Double?
    /// 当前统计周期的起始时间
    private var lastCheckTime: Date = Date()
    /// 当前 1 秒时间窗口内已消耗的字节数
    private var bytesAccumulatedInWindow: Double = 0

    public init(maxBytesPerSecond: Double? = nil) {
        self.maxBytesPerSecond = maxBytesPerSecond
    }

    /// 动态更新限速阈值
    public func setMaxBytesPerSecond(_ limit: Double?) {
        self.maxBytesPerSecond = limit
        self.bytesAccumulatedInWindow = 0
        self.lastCheckTime = Date()
    }

    /// 检查并按需进行微秒级休眠节流，确保带宽不超出上限
    /// - Parameter chunkSize: 本次刚刚拉取完成的数据分块大小（字节）
    public func throttle(chunkSize: Int) async {
        guard let limit = maxBytesPerSecond, limit > 0 else { return }

        let now = Date()
        let elapsed = now.timeIntervalSince(lastCheckTime)

        if elapsed >= 1.0 {
            // 进入新的 1 秒计费周期，重置窗口累加器
            lastCheckTime = now
            bytesAccumulatedInWindow = Double(chunkSize)
        } else {
            bytesAccumulatedInWindow += Double(chunkSize)
            // 如果在当前秒内已经消耗完毕配额，主动让出线程进入休眠
            if bytesAccumulatedInWindow > limit {
                let remainingWindow = 1.0 - elapsed
                if remainingWindow > 0 {
                    let sleepNanoseconds = UInt64(remainingWindow * 1_000_000_000)
                    try? await Task.sleep(nanoseconds: sleepNanoseconds)
                }
                lastCheckTime = Date()
                bytesAccumulatedInWindow = 0
            }
        }
    }
}
