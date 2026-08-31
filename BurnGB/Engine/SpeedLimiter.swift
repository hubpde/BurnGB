//
//  SpeedLimiter.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import Foundation

/// Token-bucket based speed limiter for controlling bandwidth usage
public actor SpeedLimiter {
    private var maxBytesPerSecond: Double?
    private var lastCheckTime: Date = Date()
    private var bytesAccumulatedInWindow: Double = 0

    public init(maxBytesPerSecond: Double? = nil) {
        self.maxBytesPerSecond = maxBytesPerSecond
    }

    public func setMaxBytesPerSecond(_ limit: Double?) {
        self.maxBytesPerSecond = limit
        self.bytesAccumulatedInWindow = 0
        self.lastCheckTime = Date()
    }

    /// Throttles if exceeding the current window's byte budget
    public func throttle(chunkSize: Int) async {
        guard let limit = maxBytesPerSecond, limit > 0 else { return }

        let now = Date()
        let elapsed = now.timeIntervalSince(lastCheckTime)

        if elapsed >= 1.0 {
            // New 1-second window
            lastCheckTime = now
            bytesAccumulatedInWindow = Double(chunkSize)
        } else {
            bytesAccumulatedInWindow += Double(chunkSize)
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
