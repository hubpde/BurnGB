//
//  MainDashboardView.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import SwiftUI

public struct MainDashboardView: View {
    @StateObject private var engine = BurnEngine.shared

    @State private var showNodeSelection = false
    @State private var showQuotaSheet = false
    @State private var showSpeedLimitSheet = false
    @State private var showIPSheet = false
    @State private var showSettingsSheet = false
    @State private var showPredictionDetails = false

    public init() {}

    public var body: some View {
        ZStack {
            // Liquid Mesh Ambient Background
            LiquidMeshBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Top Navigation Header
                    headerBar

                    // Hero Liquid Gauge
                    gaugeSection

                    // Stats Cards Row
                    statsCardsSection

                    // Quick Configuration Badges
                    quickConfigRow

                    // Thread Slider Card
                    threadsSliderCard

                    // Real-time Speed Spline Chart Card
                    SpeedChartView(samples: engine.speedSamples, isRunning: engine.isRunning)
                        .padding(18)
                        .liquidGlass(cornerRadius: 22)

                    // Prediction Forecast Card
                    predictionCard

                    // Primary Action Control Button
                    actionButtonSection

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
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

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(LiquidTheme.burningGradient)
                Text("BurnGB")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()

            HStack(spacing: 12) {
                // IP Probe Button
                Button {
                    HapticManager.impact(.light)
                    showIPSheet = true
                } label: {
                    Image(systemName: "network")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(10)
                        .liquidGlass(cornerRadius: 14, innerTint: Color.white.opacity(0.08))
                }

                // Settings Button
                Button {
                    HapticManager.impact(.light)
                    showSettingsSheet = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(10)
                        .liquidGlass(cornerRadius: 14, innerTint: Color.white.opacity(0.08))
                }
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Gauge Section

    private var gaugeSection: some View {
        let speedFormatted = ByteFormatter.formatSpeed(engine.currentSpeedBytesPerSec)
        let bitrateFormatted = ByteFormatter.formatFullBitrate(engine.currentSpeedBytesPerSec)

        var progress: Double = 0.0
        if let quota = engine.targetQuotaBytes, quota > 0 {
            progress = Double(engine.totalBytesBurned) / Double(quota)
        } else {
            // Dynamic scale up to 100MB/s
            progress = engine.currentSpeedBytesPerSec / (100 * 1024 * 1024)
        }

        return VStack(spacing: 14) {
            LiquidGaugeView(
                speedValue: speedFormatted.value,
                speedUnit: speedFormatted.unit,
                bitrateText: bitrateFormatted,
                progress: progress,
                isRunning: engine.isRunning && !engine.isPaused,
                flameMode: true
            )

            // Current Node Selector Pill
            Button {
                HapticManager.selection()
                showNodeSelection = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: engine.currentNode.iconName)
                        .foregroundColor(LiquidTheme.cyanPrimary)
                    Text(engine.currentNode.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .liquidGlass(cornerRadius: 18, innerTint: Color.white.opacity(0.06))
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Stats Cards Section

    private var statsCardsSection: some View {
        HStack(spacing: 12) {
            // Burned Total Card
            LiquidGlassCard(padding: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("累计消耗")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    let burned = ByteFormatter.formatBytes(engine.totalBytesBurned)
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text(burned.value)
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text(burned.unit)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(LiquidTheme.flameSecondary)
                    }

                    if let quota = engine.targetQuotaBytes {
                        Text("/ \(ByteFormatter.formatFullBytes(quota))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.45))
                    }
                }
            }

            // Average Speed Card
            LiquidGlassCard(padding: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("平均速率")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    let avg = ByteFormatter.formatSpeed(engine.averageSpeedBytesPerSec)
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text(avg.value)
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text(avg.unit)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(LiquidTheme.cyanPrimary)
                    }

                    Text("峰值 \(ByteFormatter.formatFullSpeed(engine.peakSpeedBytesPerSec))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.45))
                }
            }

            // Duration Card
            LiquidGlassCard(padding: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("持续时间")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    Text(TimeFormatter.formatDuration(engine.elapsedTime))
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)

                    Text(engine.isRunning ? (engine.isPaused ? "已暂停" : "狂飙中") : "已就绪")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(engine.isRunning ? LiquidTheme.emerald : .white.opacity(0.45))
                }
            }
        }
    }

    // MARK: - Quick Configuration Row

    private var quickConfigRow: some View {
        HStack(spacing: 12) {
            // Quantitative Quota Pill
            Button {
                HapticManager.selection()
                showQuotaSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                        .font(.system(size: 13))
                    Text(engine.targetQuotaBytes != nil ? "定量: \(ByteFormatter.formatFullBytes(engine.targetQuotaBytes!))" : "定量: 无上限")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(engine.targetQuotaBytes != nil ? LiquidTheme.flamePrimary : .white.opacity(0.85))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .liquidGlass(
                    cornerRadius: 16,
                    innerTint: engine.targetQuotaBytes != nil ? LiquidTheme.flamePrimary.opacity(0.12) : Color.white.opacity(0.04)
                )
            }

            // Speed Limit Pill
            Button {
                HapticManager.selection()
                showSpeedLimitSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "speedometer")
                        .font(.system(size: 13))
                    Text(engine.speedLimitBytesPerSec != nil ? "限速: \(ByteFormatter.formatFullBitrate(engine.speedLimitBytesPerSec!))" : "限速: 无限制")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(engine.speedLimitBytesPerSec != nil ? LiquidTheme.cyanPrimary : .white.opacity(0.85))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .liquidGlass(
                    cornerRadius: 16,
                    innerTint: engine.speedLimitBytesPerSec != nil ? LiquidTheme.cyanPrimary.opacity(0.12) : Color.white.opacity(0.04)
                )
            }
        }
    }

    // MARK: - Threads Slider Card

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

    // MARK: - Prediction Card

    private var predictionCard: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("消耗速率预测", systemImage: "calendar.badge.clock")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                    Spacer()
                }

                HStack(spacing: 8) {
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
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.03))
        )
    }

    // MARK: - Action Buttons

    private var actionButtonSection: some View {
        VStack(spacing: 12) {
            if !engine.isRunning {
                LiquidGlassButton(
                    title: "立即点火消耗",
                    icon: "flame.fill",
                    style: .burning,
                    isFullWidth: true,
                    isPulseActive: true
                ) {
                    engine.start()
                }
            } else {
                HStack(spacing: 14) {
                    // Pause / Resume Button
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

                    // Stop Button
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

            // Reset Button
            if engine.totalBytesBurned > 0 && !engine.isRunning {
                Button {
                    engine.resetStats()
                } label: {
                    Text("重置消耗统计")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.vertical, 6)
                }
            }
        }
        .padding(.top, 4)
    }
}
