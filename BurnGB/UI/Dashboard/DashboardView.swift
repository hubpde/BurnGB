//
//  DashboardView.swift
//  BurnGB
//
//  iOS 26 主仪表盘：先看状态，再做控制，配置项放在次级层级。
//

import SwiftUI
import BurnGBCore

/// BurnGB 的主工作台。
struct DashboardView: View {
    @Environment(AppModel.self) private var model
    @State private var presentedSheet: DashboardSheet?
    @State private var showsResetConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HeroMetricView(snapshot: model.snapshot)

                MetricGridView(snapshot: model.snapshot)

                RunControlsView()

                if let message = model.errorMessage {
                    Label(message, systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 4)
                        .accessibilityLabel("错误：\(message)")
                }

                ConfigurationSummaryView { sheet in
                    presentedSheet = sheet
                }

                ThroughputChartView(snapshot: model.snapshot)
                    .padding()
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                ForecastView(snapshot: model.snapshot)

                if !model.isRunning, model.snapshot.totalBytes > 0 {
                    Button("重置本次统计", role: .destructive) {
                        showsResetConfirmation = true
                    }
                    .frame(maxWidth: .infinity)
                }

                Text("应用层收到的字节数仅用于本次任务统计，不等同于运营商最终计费字节。请只使用自己拥有或明确获授权的节点。")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("概览")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("节点", systemImage: "network") { presentedSheet = .node }
                    Button("定量上限", systemImage: "gauge.with.dots.needle.bottom.50percent") { presentedSheet = .quota }
                    Button("带宽限速", systemImage: "speedometer") { presentedSheet = .rateLimit }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("配置任务")
            }
        }
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .node:
                NodePickerSheetView()
            case .quota:
                QuotaEditorView(
                    quotaBytes: Binding(
                        get: { model.quotaBytes },
                        set: { model.quotaBytes = $0 }
                    )
                )
            case .rateLimit:
                RateLimitEditorView(
                    bytesPerSecond: Binding(
                        get: { model.rateLimitBytesPerSecond },
                        set: { model.setRateLimit($0) }
                    )
                )
            }
        }
        .confirmationDialog(
            "重置本次统计？",
            isPresented: $showsResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("重置", role: .destructive) { model.reset() }
            Button("取消", role: .cancel) {}
        }
        .alert(
            "提示",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            )
        ) {
            Button("知道了") { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }
}

/// 预测消耗展示，作为次要信息放在主操作之后。
private struct ForecastView: View {
    let snapshot: TrafficSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("按当前速率估算", systemImage: "clock.arrow.2.circlepath")
                .font(.headline)

            let speed = snapshot.speedBytesPerSecond
            HStack {
                forecast("每分钟", seconds: 60, speed: speed)
                Divider()
                forecast("每小时", seconds: 3600, speed: speed)
                Divider()
                forecast("每天", seconds: 86400, speed: speed)
            }
        }
        .padding()
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    @ViewBuilder
    private func forecast(_ title: LocalizedStringKey, seconds: Double, speed: Double) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(ByteFormatting.bytes(Int64(max(0, speed * seconds))).text)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}
