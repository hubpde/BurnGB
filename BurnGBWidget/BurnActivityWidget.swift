//
//  BurnActivityWidget.swift
//  BurnGBWidget
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import WidgetKit
import SwiftUI
#if canImport(ActivityKit)
import ActivityKit

struct BurnActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BurnActivityAttributes.self) { context in
            // MARK: - Lock Screen & Banner Presentation
            lockScreenBanner(context: context)
        } dynamicIsland: { context in
            // MARK: - Dynamic Island Presentation
            DynamicIsland {
                // Expanded Leading
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.2, blue: 0.4), Color(red: 1.0, green: 0.6, blue: 0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.attributes.nodeName)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Text("\(context.state.activeThreads) 线程并发")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.leading, 4)
                }

                // Expanded Trailing
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.state.formattedSpeed)
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(red: 0.05, green: 0.85, blue: 0.95))

                        Text(context.state.formattedBitrate)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.trailing, 4)
                }

                // Expanded Center / Progress
                DynamicIslandExpandedRegion(.center) {
                    if let quotaStr = context.attributes.formattedQuota {
                        VStack(spacing: 4) {
                            ProgressView(value: context.state.progress, total: 1.0)
                                .tint(Color(red: 1.0, green: 0.36, blue: 0.15))
                                .scaleEffect(y: 1.2)

                            HStack {
                                Text("已耗 \(context.state.formattedBurned)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.85))
                                Spacer()
                                Text("目标 \(quotaStr)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                    }
                }

                // Expanded Bottom
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(context.state.isRunning && !context.state.isPaused ? Color.green : Color.orange)
                                .frame(width: 7, height: 7)
                            Text(context.state.isRunning ? (context.state.isPaused ? "已暂停" : "全速拉取中") : "已就绪")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.75))
                        }

                        Spacer()

                        Text("累计消耗: \(context.state.formattedBurned)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 1.0, green: 0.65, blue: 0.1))
                    }
                    .padding(.horizontal, 6)
                    .padding(.top, 2)
                }
            } compactLeading: {
                // Compact Leading
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.2, blue: 0.4), Color(red: 1.0, green: 0.6, blue: 0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            } compactTrailing: {
                // Compact Trailing
                Text(context.state.formattedSpeed)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(red: 0.05, green: 0.85, blue: 0.95))
            } minimal: {
                // Minimal
                Image(systemName: "flame.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.1))
            }
        }
    }

    // MARK: - Lock Screen Banner View (Liquid Glass Style)
    @ViewBuilder
    private func lockScreenBanner(context: ActivityViewContext<BurnActivityAttributes>) -> some View {
        ZStack {
            // Dark Frosted Background
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.13).opacity(0.92))

            // Ambient Glow Gradient
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.36, blue: 0.15).opacity(0.12),
                            Color(red: 0.05, green: 0.85, blue: 0.95).opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Specular Top Border
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.45),
                            Color.white.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )

            VStack(spacing: 12) {
                // Top Header Row
                HStack {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 1.0, green: 0.2, blue: 0.4), Color(red: 1.0, green: 0.6, blue: 0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 28, height: 28)
                            Image(systemName: "flame.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("BurnGB 流量消耗")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            Text(context.attributes.nodeName)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.state.formattedSpeed)
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(red: 0.05, green: 0.85, blue: 0.95))
                        Text(context.state.formattedBitrate)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                // Progress Bar (if quota set)
                if let quotaStr = context.attributes.formattedQuota {
                    VStack(spacing: 4) {
                        ProgressView(value: context.state.progress, total: 1.0)
                            .tint(Color(red: 1.0, green: 0.36, blue: 0.15))

                        HStack {
                            Text("已消耗 \(context.state.formattedBurned)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                            Spacer()
                            Text("定量上限 \(quotaStr)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                } else {
                    HStack {
                        Text("累计消耗: \(context.state.formattedBurned)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 1.0, green: 0.65, blue: 0.1))
                        Spacer()
                        Text("\(context.state.activeThreads) 线程全速并发")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding(16)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
#endif
