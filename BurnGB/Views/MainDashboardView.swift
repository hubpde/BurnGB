//
//  MainDashboardView.swift
//  BurnGB
//
//  Created for BurnGB - iOS Native Edition.
//

import SwiftUI

/// BurnGB 主控制仪表盘视图（100% 官方原生设计）
public struct MainDashboardView: View {
    @StateObject private var engine = BurnEngine.shared

    // MARK: - 弹窗状态
    @State private var showNodeSelection = false
    @State private var showQuotaSheet = false
    @State private var showSpeedLimitSheet = false
    @State private var showIPSheet = false
    @State private var showSettingsSheet = false

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                // 1. 核心速率大数字仪表盘区域
                Section {
                    let speedFormatted = ByteFormatter.formatSpeed(engine.currentSpeedBytesPerSec)
                    let bitrateFormatted = ByteFormatter.formatFullBitrate(engine.currentSpeedBytesPerSec)

                    HStack {
                        Spacer()
                        LiquidGaugeView(
                            speedValue: speedFormatted.value,
                            speedUnit: speedFormatted.unit,
                            bitrateText: bitrateFormatted,
                            progress: 0,
                            isRunning: engine.isRunning && !engine.isPaused
                        )
                        Spacer()
                    }
                }
                .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))

                // 2. 测速节点选择
                Section(header: Text("测速节点")) {
                    Button {
                        HapticManager.selection()
                        showNodeSelection = true
                    } label: {
                        HStack {
                            Image(systemName: engine.currentNode.iconName)
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            Text(engine.currentNode.name)
                                .foregroundColor(.primary)
                                .fontWeight(.medium)
                            Spacer()
                            Text("切换")
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // 3. 统计核心数据行
                Section(header: Text("本次消耗统计")) {
                    HStack {
                        Text("累计消耗")
                        Spacer()
                        let burned = ByteFormatter.formatBytes(engine.totalBytesBurned)
                        Text("\(burned.value) \(burned.unit)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                        if let quota = engine.targetQuotaBytes {
                            Text("/ \(ByteFormatter.formatFullBytes(quota))")
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Text("平均速率")
                        Spacer()
                        let avg = ByteFormatter.formatSpeed(engine.averageSpeedBytesPerSec)
                        Text("\(avg.value) \(avg.unit)")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.blue)
                        Text("(峰值 \(ByteFormatter.formatFullSpeed(engine.peakSpeedBytesPerSec)))")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("持续时间")
                        Spacer()
                        Text(TimeFormatter.formatDuration(engine.elapsedTime))
                            .font(.system(size: 15, weight: .medium, design: .monospaced))
                    }
                }

                // 4. 定量与限速控制
                Section(header: Text("控制与限制")) {
                    Button {
                        HapticManager.selection()
                        showQuotaSheet = true
                    } label: {
                        HStack {
                            Text("定量上限")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(engine.targetQuotaBytes != nil ? ByteFormatter.formatFullBytes(engine.targetQuotaBytes!) : "无限制")
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }

                    Button {
                        HapticManager.selection()
                        showSpeedLimitSheet = true
                    } label: {
                        HStack {
                            Text("带宽限速")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(engine.speedLimitBytesPerSec != nil ? ByteFormatter.formatFullBitrate(engine.speedLimitBytesPerSec!) : "无限制")
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // 5. 并发线程调节
                Section(header: Text("并发线程配置")) {
                    LiquidGlassSlider(
                        value: Binding(
                            get: { Double(engine.activeThreads) },
                            set: { engine.updateThreads(Int($0)) }
                        ),
                        in: 1...64,
                        step: 1,
                        label: "下载线程数",
                        displayValue: "\(engine.activeThreads) 线程",
                        tintColor: .orange
                    )
                }

                // 6. 实时吞吐走势图
                Section(header: Text("实时吞吐走势")) {
                    SpeedChartView(samples: engine.speedSamples, isRunning: engine.isRunning)
                        .padding(.vertical, 4)
                }

                // 7. 速率预测推算
                Section(header: Text("消耗速率推算")) {
                    HStack {
                        predictionCell(title: "每分钟", value: engine.prediction.perMinute)
                        Divider()
                        predictionCell(title: "每小时", value: engine.prediction.perHour)
                        Divider()
                        predictionCell(title: "每天", value: engine.prediction.perDay)
                        Divider()
                        predictionCell(title: "每月", value: engine.prediction.perMonth)
                    }
                    .padding(.vertical, 4)
                }

                // 8. 核心操作按钮
                Section {
                    if !engine.isRunning {
                        LiquidGlassButton(
                            title: "立即点火消耗",
                            icon: "flame.fill",
                            style: .burning
                        ) {
                            engine.start()
                        }
                    } else {
                        HStack(spacing: 12) {
                            LiquidGlassButton(
                                title: engine.isPaused ? "继续运行" : "暂停",
                                icon: engine.isPaused ? "play.fill" : "pause.fill",
                                style: .speedCyan
                            ) {
                                if engine.isPaused {
                                    engine.resume()
                                } else {
                                    engine.pause()
                                }
                            }

                            LiquidGlassButton(
                                title: "终止",
                                icon: "stop.fill",
                                style: .danger
                            ) {
                                engine.stop()
                            }
                        }
                    }

                    if engine.totalBytesBurned > 0 && !engine.isRunning {
                        Button("重置本次统计", role: .destructive) {
                            engine.resetStats()
                        }
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            .navigationTitle("BurnGB")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        HapticManager.impact(.light)
                        showIPSheet = true
                    } label: {
                        Image(systemName: "network")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticManager.impact(.light)
                        showSettingsSheet = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .sheet(isPresented: $showNodeSelection) {
            NodeSelectionView(currentNode: $engine.currentNode)
        }
        .sheet(isPresented: $showQuotaSheet) {
            QuantitativeLimitSheet(targetQuota: $engine.targetQuotaBytes)
        }
        .sheet(isPresented: $showSpeedLimitSheet) {
            SpeedLimiterSheet(speedLimitBytesPerSec: $engine.speedLimitBytesPerSec)
        }
        .sheet(isPresented: $showIPSheet) {
            IPInfoView()
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsView()
        }
    }

    @ViewBuilder
    private func predictionCell(title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}
