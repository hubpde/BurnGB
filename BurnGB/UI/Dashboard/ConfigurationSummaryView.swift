//
//  ConfigurationSummaryView.swift
//  BurnGB
//
//  主屏配置摘要与快捷入口。
//

import SwiftUI
import BurnGBCore

/// 展示当前节点、配额、限速和并发配置。
struct ConfigurationSummaryView: View {
    @Environment(AppModel.self) private var model
    let openSheet: (DashboardSheet) -> Void

    var body: some View {
        GlassControlGroup {
            VStack(spacing: 0) {
                configurationRow(
                    title: "测速节点",
                    value: model.selectedNode.name,
                    systemImage: model.selectedNode.symbolName
                ) {
                    openSheet(.node)
                }

                Divider()

                configurationRow(
                    title: "定量上限",
                    value: model.quotaBytes.map { ByteFormatting.bytes($0).text } ?? "无限制",
                    systemImage: "gauge.with.dots.needle.bottom.50percent"
                ) {
                    openSheet(.quota)
                }

                Divider()

                configurationRow(
                    title: "带宽限速",
                    value: model.rateLimitBytesPerSecond.map { ByteFormatting.bitsPerSecond($0).text } ?? "无限制",
                    systemImage: "speedometer"
                ) {
                    openSheet(.rateLimit)
                }

                Divider()

                HStack(spacing: 12) {
                    Image(systemName: "square.stack.3d.up")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    Text("并发线程")
                        .foregroundStyle(.primary)
                    Spacer()
                    Stepper(
                        value: Binding(
                            get: { model.workerCount },
                            set: { model.setWorkerCount($0) }
                        ),
                        in: 1...64
                    ) {
                        Text("\(model.workerCount)")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .labelsHidden()
                }
                .padding(.vertical, 12)
            }
            .padding(.horizontal)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    @ViewBuilder
    private func configurationRow(
        title: LocalizedStringKey,
        value: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Dashboard 使用的单一弹窗路由。
enum DashboardSheet: Identifiable, Hashable {
    case node
    case quota
    case rateLimit

    var id: Self { self }
}
