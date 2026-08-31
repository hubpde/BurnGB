//
//  ThroughputChartView.swift
//  BurnGB
//
//  使用 Swift Charts 展示最近一分钟吞吐速率。
//

import SwiftUI
import Charts
import BurnGBCore

/// 系统 Charts 版本的吞吐历史图。
struct ThroughputChartView: View {
    let snapshot: TrafficSnapshot

    private var maxSpeed: Double {
        let values = snapshot.history.map(\.bytesPerSecond)
        return max(values.max() ?? 0, snapshot.speedBytesPerSecond, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("吞吐历史", systemImage: "chart.xyaxis.line")
                    .font(.headline)
                Spacer()
                Text(ByteFormatting.bytesPerSecond(snapshot.speedBytesPerSecond).text)
                    .font(.subheadline.weight(.medium))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            if snapshot.history.isEmpty {
                ContentUnavailableView(
                    "尚未有采样",
                    systemImage: "chart.line.flattrend.xyaxis",
                    description: Text("开始任务后，这里会显示最近一分钟的网络吞吐。")
                )
                .frame(minHeight: 170)
            } else {
                Chart(snapshot.history) { point in
                    AreaMark(
                        x: .value("时间", point.timestamp),
                        y: .value("速率", point.bytesPerSecond)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.blue.opacity(0.14))

                    LineMark(
                        x: .value("时间", point.timestamp),
                        y: .value("速率", point.bytesPerSecond)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }
                .chartYScale(domain: 0...maxSpeed)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                            .foregroundStyle(.secondary.opacity(0.2))
                        AxisValueLabel {
                            if let speed = value.as(Double.self) {
                                Text(ByteFormatting.bytesPerSecond(speed).text)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine()
                            .foregroundStyle(.secondary.opacity(0.15))
                        AxisValueLabel(format: .dateTime.minute().second())
                    }
                }
                .chartScrollableAxes(.horizontal)
                .chartXVisibleDomain(length: 60)
                .chartPlotStyle { plot in
                    plot
                        .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                }
                .frame(minHeight: 190)
                .accessibilityLabel("最近一分钟网络吞吐速率图")
                .accessibilityValue("当前 \(ByteFormatting.bytesPerSecond(snapshot.speedBytesPerSecond).text)")
            }
        }
    }
}
