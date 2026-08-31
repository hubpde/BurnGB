//
//  BurnActivityAttributes.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import Foundation
#if canImport(ActivityKit)
import ActivityKit

public struct BurnActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var currentSpeedBytesPerSec: Double
        public var totalBurnedBytes: Int64
        public var progress: Double // 0.0 to 1.0 (if targetQuotaBytes is set)
        public var isRunning: Bool
        public var isPaused: Bool
        public var activeThreads: Int
        public var elapsedSeconds: Int
        public var formattedSpeed: String
        public var formattedBurned: String
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

    // Fixed non-changing attributes
    public var nodeName: String
    public var targetQuotaBytes: Int64?
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
