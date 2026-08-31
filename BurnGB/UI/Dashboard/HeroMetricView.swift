//
//  HeroMetricView.swift
//  BurnGB
//
//  主屏核心速率与定量进度展示。
//

import SwiftUI
import BurnGBCore

/// 用系统 Gauge、数字过渡和少量 Liquid Glass 组成的主指标。
struct HeroMetricView: View {
    let snapshot: TrafficSnapshot

    private var speed: FormattedValue {
        ByteFormatting.bytesPerSecond(snapshot.speedBytesPerSecond)
    }

    private var bitrate: FormattedValue {
        ByteFormatting.bitsPerSecond(snapshot.speedBytesPerSecond)
    }

    private var progress: Double {
        guard let quota = snapshot.quotaBytes, quota > 0 else { return 0 }
        return min(max(Double(snapshot.totalBytes) / Double(quota), 0), 1)
    }

    private var isActive: Bool {
        snapshot.phase == .running || snapshot.phase == .starting
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Label(statusTitle, systemImage: statusSymbol)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(statusColor)
                    .symbolEffect(.pulse, isActive: isActive)
                Spacer()
                Text(snapshot.nodeName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            VStack(spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(speed.value)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text(speed.unit)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                Text(bitrate.text)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if let quota = snapshot.quotaBytes {
                Gauge(value: progress, in: 0...1) {
                    Text("定量进度")
                } currentValueLabel: {
                    Text(progress, format: .percent.precision(.fractionLength(0)))
                        .monospacedDigit()
                } minimumValueLabel: {
                    Text(ByteFormatting.bytes(snapshot.totalBytes).text)
                } maximumValueLabel: {
                    Text(ByteFormatting.bytes(quota).text)
                }
                .gaugeStyle(.accessoryLinearCapacity)
                .tint(.orange)
                .accessibilityLabel("定量进度")
                .accessibilityValue("\(Int(progress * 100))%")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 18)
        .glassEffect(
            isActive ? .regular.tint(.orange.opacity(0.12)) : .regular,
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("当前网络消耗速率")
    }

    private var statusTitle: LocalizedStringKey {
        switch snapshot.phase {
        case .running: "正在消耗"
        case .starting: "正在启动"
        case .paused: "已暂停"
        case .completed: "已完成"
        case .failed: "发生错误"
        case .stopping: "正在停止"
        case .idle: "准备就绪"
        }
    }

    private var statusSymbol: String {
        switch snapshot.phase {
        case .running, .starting: "arrow.down.circle.fill"
        case .paused: "pause.circle.fill"
        case .completed: "checkmark.circle.fill"
        case .failed: "exclamationmark.triangle.fill"
        case .stopping: "stop.circle.fill"
        case .idle: "circle.fill"
        }
    }

    private var statusColor: Color {
        switch snapshot.phase {
        case .running, .starting: .orange
        case .paused: .yellow
        case .completed: .green
        case .failed: .red
        case .stopping, .idle: .secondary
        }
    }
}
