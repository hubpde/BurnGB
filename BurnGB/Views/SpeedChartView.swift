//
//  SpeedChartView.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import SwiftUI

/// 极简吞吐速率实时画布曲线图
public struct SpeedChartView: View {
    /// 历史采样数据序列
    public var samples: [SpeedSample]
    /// 引擎是否处于运行中
    public var isRunning: Bool

    public init(samples: [SpeedSample], isRunning: Bool = false) {
        self.samples = samples
        self.isRunning = isRunning
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("实时吞吐走势", systemImage: "chart.xyaxis.line")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                if let latest = samples.last, isRunning {
                    Text(ByteFormatter.formatFullSpeed(latest.bytesPerSec))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(LiquidTheme.cyanPrimary)
                }
            }

            if samples.isEmpty {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.02))
                    .frame(height: 95)
                    .overlay(
                        Text("等待点火启动测速...")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.3))
                    )
            } else {
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let height = proxy.size.height
                    let maxSpeed = max(samples.map { $0.bytesPerSec }.max() ?? 1.0, 1024 * 1024)

                    ZStack {
                        // 细暗网格线
                        VStack {
                            Divider().background(Color.white.opacity(0.06))
                            Spacer()
                            Divider().background(Color.white.opacity(0.06))
                            Spacer()
                            Divider().background(Color.white.opacity(0.06))
                        }

                        // 曲线下方微光渐变填充
                        Path { path in
                            guard samples.count > 1 else { return }
                            let stepX = width / CGFloat(max(samples.count - 1, 1))

                            path.move(to: CGPoint(x: 0, y: height))

                            for (index, sample) in samples.enumerated() {
                                let x = CGFloat(index) * stepX
                                let normalized = CGFloat(sample.bytesPerSec / maxSpeed)
                                let y = height - (normalized * (height - 8))
                                path.addLine(to: CGPoint(x: x, y: y))
                            }

                            path.addLine(to: CGPoint(x: CGFloat(samples.count - 1) * stepX, y: height))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [
                                    LiquidTheme.cyanPrimary.opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        // 走势折线
                        Path { path in
                            guard samples.count > 1 else { return }
                            let stepX = width / CGFloat(max(samples.count - 1, 1))

                            for (index, sample) in samples.enumerated() {
                                let x = CGFloat(index) * stepX
                                let normalized = CGFloat(sample.bytesPerSec / maxSpeed)
                                let y = height - (normalized * (height - 8))
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(
                            LiquidTheme.cyanPrimary,
                            style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
                        )
                    }
                }
                .frame(height: 95)
            }
        }
    }
}
