//
//  QuotaLedger.swift
//  BurnGBCore
//
//  严格配额账本：所有字节计数和上限判断在同一 actor 内完成。
//

import Foundation

/// 负责精确累计流量并在多 worker 并发下裁剪配额的 actor。
public actor QuotaLedger {
    private let quotaBytes: Int64?
    private var receivedBytes: Int64 = 0
    private var acceptedBytes: Int64 = 0

    public init(quotaBytes: Int64?) {
        self.quotaBytes = quotaBytes.flatMap { $0 > 0 ? $0 : nil }
    }

    /// 原子接收一个网络分块。
    /// 即使多个 worker 同时调用，也只会放行未超过上限的字节数。
    public func ingest(_ byteCount: Int) -> QuotaDecision {
        guard byteCount > 0 else {
            return QuotaDecision(
                receivedBytes: receivedBytes,
                acceptedBytes: 0,
                totalBytes: acceptedBytes,
                reachedQuota: quotaBytes.map { acceptedBytes >= $0 } ?? false
            )
        }

        let safeCount = Int64(byteCount)
        receivedBytes = saturatingAdd(receivedBytes, safeCount)

        let remaining: Int64
        if let quotaBytes {
            remaining = max(0, quotaBytes - acceptedBytes)
        } else {
            remaining = Int64.max
        }

        let accepted = min(safeCount, remaining)
        acceptedBytes = saturatingAdd(acceptedBytes, accepted)
        let reached = quotaBytes.map { acceptedBytes >= $0 } ?? false

        return QuotaDecision(
            receivedBytes: receivedBytes,
            acceptedBytes: accepted,
            totalBytes: acceptedBytes,
            reachedQuota: reached
        )
    }

    /// 返回当前账本数值。
    public func totals() -> (received: Int64, accepted: Int64, reachedQuota: Bool) {
        (
            receivedBytes,
            acceptedBytes,
            quotaBytes.map { acceptedBytes >= $0 } ?? false
        )
    }

    /// 饱和加法，避免极长任务的 Int64 溢出。
    private func saturatingAdd(_ lhs: Int64, _ rhs: Int64) -> Int64 {
        if rhs > 0 && lhs > Int64.max - rhs { return Int64.max }
        return lhs + rhs
    }
}
