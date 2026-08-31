//
//  MetricGridView.swift
//  BurnGB
//
//  主屏统计指标网格。
//

import SwiftUI
import BurnGBCore

/// 用系统 LabeledContent 和 Grid 展示核心统计。
struct MetricGridView: View {
    let snapshot: TrafficSnapshot

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metric(
                title: "累计消耗",
                value: ByteFormatting.bytes(snapshot.totalBytes).text,
                detail: snapshot.quotaBytes.map { "目标 \(ByteFormatting.bytes($0).text)" },
                color: .orange,
                symbol: "arrow.down.circle"
            )
            metric(
                title: "平均速率",
                value: ByteFormatting.bytesPerSecond(snapshot.averageSpeedBytesPerSecond).text,
                detail: nil,
                color: .blue,
                symbol: "chart.line.uptrend.xyaxis"
            )
            metric(
                title: "峰值速率",
                value: ByteFormatting.bytesPerSecond(snapshot.peakSpeedBytesPerSecond).text,
                detail: nil,
                color: .purple,
                symbol: "speedometer"
            )
            metric(
                title: "运行时长",
                value: ByteFormatting.duration(snapshot.elapsedSeconds),
                detail: backgroundDetail,
                color: .green,
                symbol: "clock"
            )
        }
    }

    @ViewBuilder
    private func metric(
        title: LocalizedStringKey,
        value: String,
        detail: String?,
        color: Color,
        symbol: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .metricValueStyle(color: color)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            if let detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var backgroundDetail: String? {
        switch snapshot.backgroundState {
        case .foreground: "前台运行"
        case .submitting: "正在请求后台"
        case .running: "系统后台任务"
        case .waitingForSystem: "等待系统调度"
        case .unavailable: "后台不可用"
        case .expired: "后台任务已过期"
        case .interrupted: "后台已中断"
        }
    }
}
