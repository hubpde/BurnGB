//
//  SpeedChartView.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import SwiftUI

public struct SpeedChartView: View {
    public var samples: [SpeedSample]
    public var isRunning: Bool

    public init(samples: [SpeedSample], isRunning: Bool = false) {
        self.samples = samples
        self.isRunning = isRunning
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("实时吞吐走势", systemImage: "chart.xyaxis.line")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                if let latest = samples.last, isRunning {
                    Text(ByteFormatter.formatFullSpeed(latest.bytesPerSec))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(LiquidTheme.cyanPrimary)
                }
            }

            if samples.isEmpty {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.02))
                    .frame(height: 110)
                    .overlay(
                        Text("等待点火启动测速...")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.3))
                    )
            } else {
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let height = proxy.size.height
                    let maxSpeed = max(samples.map { $0.bytesPerSec }.max() ?? 1.0, 1024 * 1024)

                    ZStack {
                        // Grid lines
                        VStack {
                            Divider().background(Color.white.opacity(0.08))
                            Spacer()
                            Divider().background(Color.white.opacity(0.08))
                            Spacer()
                            Divider().background(Color.white.opacity(0.08))
                        }

                        // Gradient fill under curve
                        Path { path in
                            guard samples.count > 1 else { return }
                            let stepX = width / CGFloat(max(samples.count - 1, 1))

                            path.move(to: CGPoint(x: 0, y: height))

                            for (index, sample) in samples.enumerated() {
                                let x = CGFloat(index) * stepX
                                let normalized = CGFloat(sample.bytesPerSec / maxSpeed)
                                let y = height - (normalized * (height - 10))
                                if index == 0 {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }

                            path.addLine(to: CGPoint(x: CGFloat(samples.count - 1) * stepX, y: height))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [
                                    LiquidTheme.cyanPrimary.opacity(0.35),
                                    LiquidTheme.violetPrimary.opacity(0.15),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        // Top stroke line
                        Path { path in
                            guard samples.count > 1 else { return }
                            let stepX = width / CGFloat(max(samples.count - 1, 1))

                            for (index, sample) in samples.enumerated() {
                                let x = CGFloat(index) * stepX
                                let normalized = CGFloat(sample.bytesPerSec / maxSpeed)
                                let y = height - (normalized * (height - 10))
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(
                            LinearGradient(
                                colors: [LiquidTheme.cyanPrimary, LiquidTheme.flameSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)
                        )
                        .shadow(color: LiquidTheme.cyanPrimary.opacity(0.6), radius: 6, x: 0, y: 2)
                    }
                }
                .frame(height: 110)
            }
        }
    }
}
