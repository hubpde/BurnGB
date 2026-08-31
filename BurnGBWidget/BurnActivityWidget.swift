//
//  BurnActivityWidget.swift
//  BurnGB
//
//  iOS 26 官方实时活动与灵动岛界面。
//

import SwiftUI
import WidgetKit
@preconcurrency import ActivityKit
import BurnGBCore

/// BurnGB 实时活动 Widget。
struct BurnActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BurnActivityAttributes.self) { context in
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // 展开态左侧：节点和 worker 数。
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Label("BurnGB", systemImage: "arrow.down.circle.fill")
                            .font(.headline)
                        Text(context.attributes.nodeName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text("\(context.state.activeWorkers) 个 worker")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // 展开态右侧：当前速率。
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(ByteFormatting.bytesPerSecond(context.state.speedBytesPerSecond).text)
                            .font(.headline)
                            .monospacedDigit()
                            .foregroundStyle(.blue)
                        Text(ByteFormatting.bitsPerSecond(context.state.speedBytesPerSecond).text)
                            .font(.caption2)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }

                // 展开态中央：配额进度或累计值。
                DynamicIslandExpandedRegion(.center) {
                    if let quota = context.state.quotaBytes, quota > 0 {
                        VStack(spacing: 4) {
                            ProgressView(value: progress(for: context.state), total: 1)
                                .tint(.orange)
                            HStack {
                                Text(ByteFormatting.bytes(context.state.totalBytes).text)
                                Spacer()
                                Text(ByteFormatting.bytes(quota).text)
                            }
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("累计 \(ByteFormatting.bytes(context.state.totalBytes).text)")
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                    }
                }

                // 展开态底部：状态与运行时长。
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Label(statusText(context.state), systemImage: statusSymbol(context.state))
                            .font(.caption)
                            .foregroundStyle(context.isStale ? .secondary : .primary)
                        Spacer()
                        Text(context.state.startedAt, style: .timer)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(.orange)
            } compactTrailing: {
                Text(ByteFormatting.bytesPerSecond(context.state.speedBytesPerSecond).text)
                    .font(.caption2.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.blue)
            } minimal: {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(.orange)
            }
            .widgetURL(URL(string: "burngb://dashboard"))
        }
    }

    /// 锁屏实时活动视图，使用系统提供的背景容器，不自绘伪玻璃。
    @ViewBuilder
    private func lockScreenView(
        context: ActivityViewContext<BurnActivityAttributes>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("BurnGB", systemImage: "arrow.down.circle.fill")
                    .font(.headline)
                Spacer()
                Text(ByteFormatting.bytesPerSecond(context.state.speedBytesPerSecond).text)
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(.blue)
            }

            HStack {
                Text(context.attributes.nodeName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                Text(statusText(context.state))
                    .font(.caption)
                    .foregroundStyle(context.isStale ? .secondary : .primary)
            }

            if let quota = context.state.quotaBytes, quota > 0 {
                ProgressView(value: progress(for: context.state), total: 1)
                    .tint(.orange)
                HStack {
                    Text("已消耗 \(ByteFormatting.bytes(context.state.totalBytes).text)")
                    Spacer()
                    Text("目标 \(ByteFormatting.bytes(quota).text)")
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            } else {
                HStack {
                    Text("累计 \(ByteFormatting.bytes(context.state.totalBytes).text)")
                    Spacer()
                    Text("运行 ") + Text(context.state.startedAt, style: .timer)
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            }

            if context.isStale {
                Label("等待系统更新", systemImage: "clock.badge.exclamationmark")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color.clear
        }
        .widgetURL(URL(string: "burngb://dashboard"))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("BurnGB 网络流量消耗")
        .accessibilityValue("\(ByteFormatting.bytesPerSecond(context.state.speedBytesPerSecond).text)，累计 \(ByteFormatting.bytes(context.state.totalBytes).text)")
    }

    private func progress(for state: BurnActivityAttributes.ContentState) -> Double {
        guard let quota = state.quotaBytes, quota > 0 else { return 0 }
        return min(max(Double(state.totalBytes) / Double(quota), 0), 1)
    }

    private func statusText(_ state: BurnActivityAttributes.ContentState) -> String {
        switch state.phase {
        case .running: return state.backgroundState == .running ? "后台运行中" : "消耗中"
        case .starting: return "启动中"
        case .paused: return "已暂停"
        case .completed: return "已完成"
        case .failed: return "发生错误"
        case .stopping: return "正在停止"
        case .idle: return "已就绪"
        }
    }

    private func statusSymbol(_ state: BurnActivityAttributes.ContentState) -> String {
        switch state.phase {
        case .running, .starting: "arrow.down"
        case .paused: "pause"
        case .completed: "checkmark"
        case .failed: "exclamationmark.triangle"
        case .stopping: "stop"
        case .idle: "circle"
        }
    }
}
