//
//  SpeedLimiterSheet.swift
//  BurnGB
//
//  Created for BurnGB - iOS Native Edition.
//

import SwiftUI

/// 带宽限速设置弹窗视图（标准 iOS Form 表单设计）
public struct SpeedLimiterSheet: View {
    @Binding public var speedLimitBytesPerSec: Double?
    @Environment(\.dismiss) private var dismiss

    @State private var customValue: String = ""
    @State private var customUnit: String = "Mbps"

    /// 常用快捷带宽档位
    private let presets: [(label: String, bytesPerSec: Double)] = [
        ("20 Mbps", 20 * 1000 * 1000 / 8.0),
        ("50 Mbps", 50 * 1000 * 1000 / 8.0),
        ("100 Mbps", 100 * 1000 * 1000 / 8.0),
        ("300 Mbps", 300 * 1000 * 1000 / 8.0),
        ("500 Mbps", 500 * 1000 * 1000 / 8.0),
        ("1000 Mbps", 1000 * 1000 * 1000 / 8.0)
    ]

    public init(speedLimitBytesPerSec: Binding<Double?>) {
        self._speedLimitBytesPerSec = speedLimitBytesPerSec
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "speedometer")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("带宽平滑限速")
                                .font(.system(size: 15, weight: .semibold))
                            Text("限制最高拉取速率，防止挤占全部家庭或蜂窝网络。")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("快捷预设档位")) {
                    ForEach(presets, id: \.bytesPerSec) { preset in
                        Button {
                            HapticManager.selection()
                            speedLimitBytesPerSec = preset.bytesPerSec
                            dismiss()
                        } label: {
                            HStack {
                                Text(preset.label)
                                    .foregroundColor(.primary)
                                Spacer()
                                if let current = speedLimitBytesPerSec, abs(current - preset.bytesPerSec) < 100 {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                }

                Section(header: Text("自定义限速")) {
                    HStack {
                        TextField("输入数值 (如: 80)", text: $customValue)
                            .keyboardType(.decimalPad)

                        Picker("单位", selection: $customUnit) {
                            Text("Mbps").tag("Mbps")
                            Text("Gbps").tag("Gbps")
                            Text("MB/s").tag("MB/s")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 170)
                    }

                    Button("应用限速") {
                        applyCustom()
                    }
                    .disabled(customValue.isEmpty)
                }

                if speedLimitBytesPerSec != nil {
                    Section {
                        Button("解除限速（全速无限制）", role: .destructive) {
                            HapticManager.impact(.medium)
                            speedLimitBytesPerSec = nil
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("带宽限速")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func applyCustom() {
        guard let num = Double(customValue), num > 0 else { return }
        var bytesPerSec: Double = 0
        if customUnit == "Mbps" {
            bytesPerSec = num * 1000 * 1000 / 8.0
        } else if customUnit == "Gbps" {
            bytesPerSec = num * 1000 * 1000 * 1000 / 8.0
        } else if customUnit == "MB/s" {
            bytesPerSec = num * 1024 * 1024
        }

        speedLimitBytesPerSec = bytesPerSec
        HapticManager.notification(.success)
        dismiss()
    }
}
