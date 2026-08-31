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

/// 灵动岛（Dynamic Island）与锁屏实时活动 Widget 组件
struct BurnActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BurnActivityAttributes.self) { context in
            // MARK: - 1. 锁屏与横幅通知展示形态
            lockScreenBanner(context: context)
        } dynamicIsland: { context in
            // MARK: - 2. 灵动岛各形态动态适配
            DynamicIsland {
                // MARK: 展开形态 - 左侧区域
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.35, blue: 0.12), Color(red: 1.0, green: 0.62, blue: 0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        VStack(alignment: .leading, spacing: 1) {
                            Text(context.attributes.nodeName)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Text("\(context.state.activeThreads) 线程并发")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.leading, 4)
                }

                // MARK: 展开形态 - 右侧区域
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(context.state.formattedSpeed)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(red: 0.15, green: 0.78, blue: 0.95))

                        Text(context.state.formattedBitrate)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.trailing, 4)
                }

                // MARK: 展开形态 - 中间进度条
                DynamicIslandExpandedRegion(.center) {
                    if let quotaStr = context.attributes.formattedQuota {
                        VStack(spacing: 3) {
                            ProgressView(value: context.state.progress, total: 1.0)
                                .tint(Color(red: 1.0, green: 0.35, blue: 0.12))

                            HStack {
                                Text("已消耗 \(context.state.formattedBurned)")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text("目标 \(quotaStr)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.55))
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.top, 2)
                    }
                }

                // MARK: 展开形态 - 底部状态
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(context.state.isRunning && !context.state.isPaused ? Color.green : Color.orange)
                                .frame(width: 6, height: 6)
                            Text(context.state.isRunning ? (context.state.isPaused ? "已暂停" : "全速拉取中") : "已就绪")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }

                        Spacer()

                        Text("累计: \(context.state.formattedBurned)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 1.0, green: 0.62, blue: 0.15))
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 2)
                }
            } compactLeading: {
                // MARK: 紧凑左侧（图标与状态）
                Image(systemName: "flame.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.35, blue: 0.12), Color(red: 1.0, green: 0.62, blue: 0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            } compactTrailing: {
                // MARK: 紧凑右侧（实时速率）
                Text(context.state.formattedSpeed)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.15, green: 0.78, blue: 0.95))
            } minimal: {
                // MARK: 极简形态（单一能量火焰）
                Image(systemName: "flame.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(red: 1.0, green: 0.35, blue: 0.12))
            }
        }
    }

    // MARK: - 3. 锁屏液态玻璃风格横幅卡片

    @ViewBuilder
    private func lockScreenBanner(context: ActivityViewContext<BurnActivityAttributes>) -> some View {
        ZStack {
            // 深邃微磨砂底板
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.12).opacity(0.92))

            // 0.6pt 细微边缘折射描边
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.6
                )

            VStack(spacing: 10) {
                // 顶部信息行
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.35, blue: 0.12), Color(red: 1.0, green: 0.62, blue: 0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        VStack(alignment: .leading, spacing: 1) {
                            Text("BurnGB 流量消耗")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            Text(context.attributes.nodeName)
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 1) {
                        Text(context.state.formattedSpeed)
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(red: 0.15, green: 0.78, blue: 0.95))
                        Text(context.state.formattedBitrate)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.55))
                    }
                }

                // 进度条与定量统计
                if let quotaStr = context.attributes.formattedQuota {
                    VStack(spacing: 3) {
                        ProgressView(value: context.state.progress, total: 1.0)
                            .tint(Color(red: 1.0, green: 0.35, blue: 0.12))

                        HStack {
                            Text("已消耗 \(context.state.formattedBurned)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                            Text("定量上限 \(quotaStr)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.55))
                        }
                    }
                } else {
                    HStack {
                        Text("累计消耗: \(context.state.formattedBurned)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 1.0, green: 0.62, blue: 0.15))
                        Spacer()
                        Text("\(context.state.activeThreads) 线程全速并发")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.55))
                    }
                }
            }
            .padding(14)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }
}
#endif
