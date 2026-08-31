//
//  BurnActivityWidget.swift
//  BurnGBWidget
//
//  Created for BurnGB - iOS Native Edition.
//

import WidgetKit
import SwiftUI
#if canImport(ActivityKit)
import ActivityKit

/// 官方灵动岛（Dynamic Island）与实时活动（Live Activity）Widget 组件
struct BurnActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BurnActivityAttributes.self) { context in
            // MARK: - 1. 锁屏与横幅通知展示形态（官方原生设计）
            lockScreenBanner(context: context)
        } dynamicIsland: { context in
            // MARK: - 2. 灵动岛各形态动态适配
            DynamicIsland {
                // MARK: 展开形态 - 左侧区域
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.orange)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(context.attributes.nodeName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Text("\(context.state.activeThreads) 线程")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.leading, 4)
                }

                // MARK: 展开形态 - 右侧区域
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(context.state.formattedSpeed)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)

                        Text(context.state.formattedBitrate)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(.trailing, 4)
                }

                // MARK: 展开形态 - 中间定量进度条
                DynamicIslandExpandedRegion(.center) {
                    if let quotaStr = context.attributes.formattedQuota {
                        VStack(spacing: 3) {
                            ProgressView(value: context.state.progress, total: 1.0)
                                .tint(.orange)

                            HStack {
                                Text("已耗 \(context.state.formattedBurned)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("目标 \(quotaStr)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
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
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text("累计: \(context.state.formattedBurned)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 2)
                }
            } compactLeading: {
                // MARK: 紧凑左侧（火焰图标）
                Image(systemName: "flame.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.orange)
            } compactTrailing: {
                // MARK: 紧凑右侧（实时速率）
                Text(context.state.formattedSpeed)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
            } minimal: {
                // MARK: 极简形态（单一能量火焰）
                Image(systemName: "flame.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.orange)
            }
        }
    }

    // MARK: - 3. 锁屏实时活动横幅（官方标准原生设计）
    @ViewBuilder
    private func lockScreenBanner(context: ActivityViewContext<BurnActivityAttributes>) -> some View {
        VStack(spacing: 10) {
            // 顶部节点与速率
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.orange)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("BurnGB")
                            .font(.system(size: 13, weight: .semibold))
                        Text(context.attributes.nodeName)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(context.state.formattedSpeed)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    Text(context.state.formattedBitrate)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }

            // 进度与用量
            if let quotaStr = context.attributes.formattedQuota {
                VStack(spacing: 3) {
                    ProgressView(value: context.state.progress, total: 1.0)
                        .tint(.orange)

                    HStack {
                        Text("已消耗 \(context.state.formattedBurned)")
                            .font(.system(size: 10, weight: .medium))
                        Spacer()
                        Text("目标 \(quotaStr)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                HStack {
                    Text("累计消耗: \(context.state.formattedBurned)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.orange)
                    Spacer()
                    Text("\(context.state.activeThreads) 线程并发")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }
}
#endif
