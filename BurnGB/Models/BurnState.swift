//
//  BurnState.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import Foundation

/// 字节与网络速率转换格式化工具类
public enum ByteFormatter {
    private static let byteUnits = ["B", "KB", "MB", "GB", "TB", "PB"]
    private static let speedUnits = ["B/s", "KB/s", "MB/s", "GB/s", "TB/s"]
    private static let bitUnits = ["bps", "Kbps", "Mbps", "Gbps", "Tbps"]

    /// 将字节数格式化为数值和单位二元组（如 ("12.45", "GB")）
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

    /// 格式化为完整字符串（如 "12.45 GB"）
    public static func formatFullBytes(_ bytes: Int64) -> String {
        let res = formatBytes(bytes)
        return "\(res.value) \(res.unit)"
    }

    /// 格式化每秒字节速率（Byte/s）
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

    /// 格式化为完整速率字符串（如 "98.5 MB/s"）
    public static func formatFullSpeed(_ bytesPerSec: Double) -> String {
        let res = formatSpeed(bytesPerSec)
        return "\(res.value) \(res.unit)"
    }

    /// 格式化为比特带宽速率（bit/s，如 "788.0 Mbps"）
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

    /// 格式化为完整带宽字符串（如 "788.0 Mbps"）
    public static func formatFullBitrate(_ bytesPerSec: Double) -> String {
        let res = formatBitrate(bytesPerSec)
        return "\(res.value) \(res.unit)"
    }
}

/// 时间间隔格式化工具类
public enum TimeFormatter {
    /// 将秒数转换为 "HH:MM:SS" 标准时分秒格式
    public static func formatDuration(_ totalSeconds: TimeInterval) -> String {
        guard totalSeconds >= 0 else { return "00:00:00" }
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        let seconds = Int(totalSeconds) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

/// 历史速率采样点数据模型（用于走势图绘制）
public struct SpeedSample: Identifiable, Hashable {
    public let id = UUID()
    /// 采样时间戳
    public let timestamp: Date
    /// 该时刻瞬时速率（Byte/s）
    public let bytesPerSec: Double

    public init(timestamp: Date = Date(), bytesPerSec: Double) {
        self.timestamp = timestamp
        self.bytesPerSec = bytesPerSec
    }
}

/// 流量消耗预测统计模型
public struct TrafficPrediction {
    /// 预计每分钟消耗
    public var perMinute: String = "-"
    /// 预计每小时消耗
    public var perHour: String = "-"
    /// 预计每天消耗
    public var perDay: String = "-"
    /// 预计每月消耗
    public var perMonth: String = "-"

    /// 根据当前瞬时速率推算不同时间窗口的消耗量
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
