//
//  SpeedChartView.swift
//  BurnGB
//
//  Created for BurnGB - iOS Native Edition.
//

import SwiftUI

/// 官方原生吞吐速率实时曲线图
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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("实时吞吐走势")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                if let latest = samples.last, isRunning {
                    Text(ByteFormatter.formatFullSpeed(latest.bytesPerSec))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(.blue)
                }
            }

            if samples.isEmpty {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(uiColor: .tertiarySystemFill).opacity(0.3))
                    .frame(height: 100)
                    .overlay(
                        Text("等待点火启动测速...")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    )
            } else {
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let height = proxy.size.height
                    let maxSpeed = max(samples.map { $0.bytesPerSec }.max() ?? 1.0, 1024 * 1024)

                    ZStack {
                        // 细网格线
                        VStack {
                            Divider()
                            Spacer()
                            Divider()
                            Spacer()
                            Divider()
                        }

                        // 曲线下方淡蓝填充
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
                        .fill(Color.blue.opacity(0.12))

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
                            Color.blue,
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                        )
                    }
                }
                .frame(height: 100)
            }
        }
    }
}
