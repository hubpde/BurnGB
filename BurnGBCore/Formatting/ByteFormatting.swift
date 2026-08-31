//
//  ByteFormatting.swift
//  BurnGBCore
//
//  流量与速率格式化工具。只传递原始数值给实时活动，展示时再格式化。
//

import Foundation

/// 展示层使用的数值和单位。
public struct FormattedValue: Hashable, Sendable {
    public let value: String
    public let unit: String

    public init(value: String, unit: String) {
        self.value = value
        self.unit = unit
    }

    public var text: String {
        "\(value) \(unit)"
    }
}

/// BurnGB 统一使用二进制字节单位、十进制比特单位。
public enum ByteFormatting {
    private static let byteUnits = ["B", "KB", "MB", "GB", "TB", "PB"]
    private static let bitUnits = ["bps", "Kbps", "Mbps", "Gbps", "Tbps"]

    /// 格式化累计字节数。
    public static func bytes(_ value: Int64) -> FormattedValue {
        guard value > 0 else { return FormattedValue(value: "0", unit: "B") }
        var number = Double(value)
        var index = 0
        while number >= 1024, index < byteUnits.count - 1 {
            number /= 1024
            index += 1
        }
        let digits = index == 0 ? 0 : (index < 2 ? 1 : 2)
        return FormattedValue(value: number.formatted(.number.precision(.fractionLength(digits))), unit: byteUnits[index])
    }

    /// 格式化 Byte/s 速率。
    public static func bytesPerSecond(_ value: Double) -> FormattedValue {
        guard value.isFinite, value > 0 else { return FormattedValue(value: "0.0", unit: "B/s") }
        var number = value
        var index = 0
        while number >= 1024, index < byteUnits.count - 1 {
            number /= 1024
            index += 1
        }
        let digits = index == 0 ? 0 : (index < 2 ? 1 : 2)
        return FormattedValue(value: number.formatted(.number.precision(.fractionLength(digits))), unit: "\(byteUnits[index])/s")
    }

    /// 格式化 bit/s 带宽。
    public static func bitsPerSecond(_ bytesPerSecond: Double) -> FormattedValue {
        guard bytesPerSecond.isFinite, bytesPerSecond > 0 else {
            return FormattedValue(value: "0.0", unit: "bps")
        }
        var number = bytesPerSecond * 8
        var index = 0
        while number >= 1000, index < bitUnits.count - 1 {
            number /= 1000
            index += 1
        }
        let digits = index < 2 ? 1 : 2
        return FormattedValue(value: number.formatted(.number.precision(.fractionLength(digits))), unit: bitUnits[index])
    }

    /// 将秒数显示为 HH:MM:SS；小时超过 99 时仍继续显示完整数值。
    public static func duration(_ seconds: TimeInterval) -> String {
        let safeSeconds = max(0, Int(seconds.rounded(.down)))
        let hours = safeSeconds / 3600
        let minutes = (safeSeconds % 3600) / 60
        let remainder = safeSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remainder)
    }
}
