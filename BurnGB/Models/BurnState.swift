//
//  BurnState.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import Foundation

public enum ByteFormatter {
    private static let byteUnits = ["B", "KB", "MB", "GB", "TB", "PB"]
    private static let speedUnits = ["B/s", "KB/s", "MB/s", "GB/s", "TB/s"]
    private static let bitUnits = ["bps", "Kbps", "Mbps", "Gbps", "Tbps"]

    public static func formatBytes(_ bytes: Int64) -> (value: String, unit: String) {
        guard bytes > 0 else { return ("0.00", "MB") }
        var doubleBytes = Double(bytes)
        var unitIndex = 0

        while doubleBytes >= 1024.0 && unitIndex < byteUnits.count - 1 {
            doubleBytes /= 1024.0
            unitIndex += 1
        }

        let format = unitIndex <= 1 ? "%.0f" : "%.2f"
        return (String(format: format, doubleBytes), byteUnits[unitIndex])
    }

    public static func formatFullBytes(_ bytes: Int64) -> String {
        let res = formatBytes(bytes)
        return "\(res.value) \(res.unit)"
    }

    public static func formatSpeed(_ bytesPerSec: Double) -> (value: String, unit: String) {
        guard bytesPerSec > 0 else { return ("0.0", "MB/s") }
        var doubleBytes = bytesPerSec
        var unitIndex = 0

        while doubleBytes >= 1024.0 && unitIndex < speedUnits.count - 1 {
            doubleBytes /= 1024.0
            unitIndex += 1
        }

        let format = unitIndex <= 1 ? "%.1f" : "%.2f"
        return (String(format: format, doubleBytes), speedUnits[unitIndex])
    }

    public static func formatFullSpeed(_ bytesPerSec: Double) -> String {
        let res = formatSpeed(bytesPerSec)
        return "\(res.value) \(res.unit)"
    }

    public static func formatBitrate(_ bytesPerSec: Double) -> (value: String, unit: String) {
        let bitsPerSec = bytesPerSec * 8.0
        guard bitsPerSec > 0 else { return ("0.0", "Mbps") }
        var doubleBits = bitsPerSec
        var unitIndex = 0

        while doubleBits >= 1000.0 && unitIndex < bitUnits.count - 1 {
            doubleBits /= 1000.0
            unitIndex += 1
        }

        let format = unitIndex <= 1 ? "%.1f" : "%.2f"
        return (String(format: format, doubleBits), bitUnits[unitIndex])
    }

    public static func formatFullBitrate(_ bytesPerSec: Double) -> String {
        let res = formatBitrate(bytesPerSec)
        return "\(res.value) \(res.unit)"
    }
}

public enum TimeFormatter {
    public static func formatDuration(_ totalSeconds: TimeInterval) -> String {
        guard totalSeconds >= 0 else { return "00:00:00" }
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        let seconds = Int(totalSeconds) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

public struct SpeedSample: Identifiable, Hashable {
    public let id = UUID()
    public let timestamp: Date
    public let bytesPerSec: Double

    public init(timestamp: Date = Date(), bytesPerSec: Double) {
        self.timestamp = timestamp
        self.bytesPerSec = bytesPerSec
    }
}

public struct TrafficPrediction {
    public var perMinute: String = "-"
    public var perHour: String = "-"
    public var perDay: String = "-"
    public var perMonth: String = "-"

    public static func calculate(fromSpeed bytesPerSec: Double) -> TrafficPrediction {
        guard bytesPerSec > 0 else { return TrafficPrediction() }
        let minBytes = Int64(bytesPerSec * 60)
        let hourBytes = Int64(bytesPerSec * 3600)
        let dayBytes = Int64(bytesPerSec * 86400)
        let monBytes = Int64(bytesPerSec * 86400 * 30)

        return TrafficPrediction(
            perMinute: ByteFormatter.formatFullBytes(minBytes),
            perHour: ByteFormatter.formatFullBytes(hourBytes),
            perDay: ByteFormatter.formatFullBytes(dayBytes),
            perMonth: ByteFormatter.formatFullBytes(monBytes)
        )
    }
}
