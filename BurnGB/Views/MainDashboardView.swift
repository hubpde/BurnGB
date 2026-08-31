//
//  MainDashboardView.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import SwiftUI

/// BurnGB 主控制仪表盘视图
/// 采用 iOS 26 极简液态玻璃风格，聚焦核心速率大数字与直观控制
public struct MainDashboardView: View {
    /// 核心引擎状态对象
    @StateObject private var engine = BurnEngine.shared

    // MARK: - 弹窗展示状态
    @State private var showNodeSelection = false
    @State private var showQuotaSheet = false
    @State private var showSpeedLimitSheet = false
    @State private var showIPSheet = false
    @State private var showSettingsSheet = false

    public init() {}

    public var body: some View {
        ZStack {
            // 极简液态磨砂漫反射背景
            LiquidMeshBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    // 1. 顶部标题与快捷操作栏
                    headerBar

                    // 2. 核心大数字速率仪表盘与当前节点切换胶囊
                    gaugeSection

                    // 3. 统计核心三连卡片（已消耗量、平均速率、运行时间）
                    statsCardsSection

                    // 4. 定量额度与限速快捷配置胶囊
                    quickConfigRow

                    // 5. 并发线程滑块调节卡片
                    threadsSliderCard

                    // 6. 实时吞吐走势画布折线图
                    SpeedChartView(samples: engine.speedSamples, isRunning: engine.isRunning)
                        .padding(16)
                        .liquidGlass(cornerRadius: 18)

                    // 7. 消耗预测卡片
                    predictionCard

                    // 8. 核心操作按钮组（点火 / 暂停 / 终止）
                    actionButtonSection

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
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

    // MARK: - 1. 顶部导航栏

    private var headerBar: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(LiquidTheme.burningGradient)
                Text("BurnGB")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()

            HStack(spacing: 10) {
                // IP 诊断按钮
                Button {
                    HapticManager.impact(.light)
                    showIPSheet = true
                } label: {
                    Image(systemName: "network")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(9)
                        .liquidGlass(cornerRadius: 12, innerTint: Color.white.opacity(0.06))
                }

                // 设置按钮
                Button {
                    HapticManager.impact(.light)
                    showSettingsSheet = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(9)
                        .liquidGlass(cornerRadius: 12, innerTint: Color.white.opacity(0.06))
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - 2. 仪表盘与节点胶囊

    private var gaugeSection: some View {
        let speedFormatted = ByteFormatter.formatSpeed(engine.currentSpeedBytesPerSec)
        let bitrateFormatted = ByteFormatter.formatFullBitrate(engine.currentSpeedBytesPerSec)

        var progress: Double = 0.0
        if let quota = engine.targetQuotaBytes, quota > 0 {
            progress = Double(engine.totalBytesBurned) / Double(quota)
        } else {
            // 无上限时按 100MB/s 动态比例展示能量弧
            progress = engine.currentSpeedBytesPerSec / (100 * 1024 * 1024)
        }

        return VStack(spacing: 12) {
            LiquidGaugeView(
                speedValue: speedFormatted.value,
                speedUnit: speedFormatted.unit,
                bitrateText: bitrateFormatted,
                progress: progress,
                isRunning: engine.isRunning && !engine.isPaused
            )

            // 当前节点选择器胶囊
            Button {
                HapticManager.selection()
                showNodeSelection = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: engine.currentNode.iconName)
                        .foregroundColor(LiquidTheme.cyanPrimary)
                        .font(.system(size: 12))
                    Text(engine.currentNode.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .liquidGlass(cornerRadius: 16, innerTint: Color.white.opacity(0.05))
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - 3. 统计核心三连卡片

    private var statsCardsSection: some View {
        HStack(spacing: 10) {
            // 已消耗总量卡片
            LiquidGlassCard(padding: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("累计消耗")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))

                    let burned = ByteFormatter.formatBytes(engine.totalBytesBurned)
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text(burned.value)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(burned.unit)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(LiquidTheme.flameSecondary)
                    }

                    if let quota = engine.targetQuotaBytes {
                        Text("/ \(ByteFormatter.formatFullBytes(quota))")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }

            // 平均速率卡片
            LiquidGlassCard(padding: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("平均速率")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))

                    let avg = ByteFormatter.formatSpeed(engine.averageSpeedBytesPerSec)
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text(avg.value)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(avg.unit)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(LiquidTheme.cyanPrimary)
                    }

                    Text("峰值 \(ByteFormatter.formatFullSpeed(engine.peakSpeedBytesPerSec))")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            // 持续时间卡片
            LiquidGlassCard(padding: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("持续时间")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))

                    Text(TimeFormatter.formatDuration(engine.elapsedTime))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)

                    Text(engine.isRunning ? (engine.isPaused ? "已暂停" : "全速中") : "已就绪")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(engine.isRunning ? LiquidTheme.emerald : .white.opacity(0.4))
                }
            }
        }
    }

    // MARK: - 4. 定量与限速快捷配置胶囊

    private var quickConfigRow: some View {
        HStack(spacing: 10) {
            // 定量上限按钮
            Button {
                HapticManager.selection()
                showQuotaSheet = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                        .font(.system(size: 12))
                    Text(engine.targetQuotaBytes != nil ? "定量: \(ByteFormatter.formatFullBytes(engine.targetQuotaBytes!))" : "定量: 无上限")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(engine.targetQuotaBytes != nil ? LiquidTheme.flamePrimary : .white.opacity(0.8))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .liquidGlass(
                    cornerRadius: 14,
                    innerTint: engine.targetQuotaBytes != nil ? LiquidTheme.flamePrimary.opacity(0.1) : Color.white.opacity(0.03)
                )
            }

            // 带宽限速按钮
            Button {
                HapticManager.selection()
                showSpeedLimitSheet = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "speedometer")
                        .font(.system(size: 12))
                    Text(engine.speedLimitBytesPerSec != nil ? "限速: \(ByteFormatter.formatFullBitrate(engine.speedLimitBytesPerSec!))" : "限速: 无限制")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(engine.speedLimitBytesPerSec != nil ? LiquidTheme.cyanPrimary : .white.opacity(0.8))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .liquidGlass(
                    cornerRadius: 14,
                    innerTint: engine.speedLimitBytesPerSec != nil ? LiquidTheme.cyanPrimary.opacity(0.1) : Color.white.opacity(0.03)
                )
            }
        }
    }

    // MARK: - 5. 并发线程调节

    private var threadsSliderCard: some View {
        LiquidGlassCard {
            LiquidGlassSlider(
                value: Binding(
                    get: { Double(engine.activeThreads) },
                    set: { engine.updateThreads(Int($0)) }
                ),
                in: 1...64,
                step: 1,
                label: "并发下载线程数",
                displayValue: "\(engine.activeThreads) 线程",
                tintColor: LiquidTheme.cyanPrimary
            )
        }
    }

    // MARK: - 6. 速率预测卡片

    private var predictionCard: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("速率预测推算", systemImage: "calendar.badge.clock")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                }

                HStack(spacing: 6) {
                    predictionItem(title: "每分钟", value: engine.prediction.perMinute)
                    predictionItem(title: "每小时", value: engine.prediction.perHour)
                    predictionItem(title: "每天", value: engine.prediction.perDay)
                    predictionItem(title: "每月", value: engine.prediction.perMonth)
                }
            }
        }
    }

    @ViewBuilder
    private func predictionItem(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.45))
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.03))
        )
    }

    // MARK: - 7. 核心操作按钮

    private var actionButtonSection: some View {
        VStack(spacing: 10) {
            if !engine.isRunning {
                LiquidGlassButton(
                    title: "立即点火消耗",
                    icon: "flame.fill",
                    style: .burning,
                    isFullWidth: true
                ) {
                    engine.start()
                }
            } else {
                HStack(spacing: 12) {
                    // 暂停 / 恢复按钮
                    LiquidGlassButton(
                        title: engine.isPaused ? "继续运行" : "暂停",
                        icon: engine.isPaused ? "play.fill" : "pause.fill",
                        style: .speedCyan,
                        isFullWidth: true
                    ) {
                        if engine.isPaused {
                            engine.resume()
                        } else {
                            engine.pause()
                        }
                    }

                    // 终止按钮
                    LiquidGlassButton(
                        title: "终止",
                        icon: "stop.fill",
                        style: .danger,
                        isFullWidth: true
                    ) {
                        engine.stop()
                    }
                }
            }

            // 重置统计按钮
            if engine.totalBytesBurned > 0 && !engine.isRunning {
                Button {
                    engine.resetStats()
                } label: {
                    Text("重置本次统计")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.vertical, 4)
                }
            }
        }
        .padding(.top, 2)
    }
}
