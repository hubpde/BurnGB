//
//  RateLimiter.swift
//  BurnGBCore
//
//  基于单调时钟的串行带宽预约器。
//

import Foundation

/// 用时间线预约实现严格背压的带宽限速器。
/// 每个分块先预约未来可读取的时间，再执行可取消的休眠，避免并发 worker 互相覆盖窗口。
public actor RateLimiter {
    private let clock = ContinuousClock()
    private var limitBytesPerSecond: Double?
    private var nextAvailableInstant: ContinuousClock.Instant?

    public init(limitBytesPerSecond: Double? = nil) {
        self.limitBytesPerSecond = limitBytesPerSecond.flatMap {
            $0.isFinite && $0 > 0 ? $0 : nil
        }
    }

    /// 更新限速并重新开始一条干净的预约时间线。
    public func setLimit(bytesPerSecond: Double?) {
        limitBytesPerSecond = bytesPerSecond.flatMap {
            $0.isFinite && $0 > 0 ? $0 : nil
        }
        nextAvailableInstant = nil
    }

    /// 在当前分块继续处理前等待可用带宽。
    /// - Parameter byteCount: 即将放行的数据量。
    public func wait(for byteCount: Int) async throws {
        guard byteCount > 0,
              let limit = limitBytesPerSecond,
              limit.isFinite,
              limit > 0 else { return }

        let now = clock.now
        let available = max(now, nextAvailableInstant ?? now)
        let nanos = Self.durationNanoseconds(for: byteCount, limit: limit)
        nextAvailableInstant = available.advanced(by: .nanoseconds(nanos))

        let waitDuration = now.duration(to: available)
        guard waitDuration > .zero else { return }
        try await clock.sleep(for: waitDuration)
    }

    /// 把分块耗时换算为纳秒，避免 Double 转整数溢出。
    private static func durationNanoseconds(for byteCount: Int, limit: Double) -> Int64 {
        let raw = (Double(byteCount) / limit) * 1_000_000_000
        guard raw.isFinite, raw > 0 else { return 0 }
        return Int64(min(raw.rounded(.up), Double(Int64.max)))
    }
}
