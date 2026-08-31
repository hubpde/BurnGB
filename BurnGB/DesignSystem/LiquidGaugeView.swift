//
//  LiquidGaugeView.swift
//  BurnGB
//
//  Created for BurnGB - iOS Native Edition.
//

import SwiftUI

/// 官方原生速率大数字与状态指示视图
public struct LiquidGaugeView: View {
    /// 速率数值文本（如 "124.5"）
    public var speedValue: String
    /// 速率单位文本（如 "MB/s"）
    public var speedUnit: String
    /// 比特带宽文本（如 "996.0 Mbps"）
    public var bitrateText: String
    /// 进度百分比（0.0 ~ 1.0）
    public var progress: Double
    /// 引擎运行状态
    public var isRunning: Bool

    public init(
        speedValue: String,
        speedUnit: String,
        bitrateText: String,
        progress: Double = 0.0,
        isRunning: Bool = false
    ) {
        self.speedValue = speedValue
        self.speedUnit = speedUnit
        self.bitrateText = bitrateText
        self.progress = min(max(progress, 0.0), 1.0)
        self.isRunning = isRunning
    }

    public var body: some View {
        VStack(spacing: 8) {
            // 状态徽标
            HStack(spacing: 6) {
                Circle()
                    .fill(isRunning ? Color.orange : Color.secondary)
                    .frame(width: 8, height: 8)
                Text(isRunning ? "全速拉取中" : "已就绪")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isRunning ? Color.orange : Color.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color(uiColor: .tertiarySystemFill))
            .clipShape(Capsule())

            // 核心超大速率数字展示
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(speedValue)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(speedUnit)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(isRunning ? Color.orange : Color.secondary)
            }

            // 带宽折算文本
            Text(bitrateText)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 16)
    }
}
