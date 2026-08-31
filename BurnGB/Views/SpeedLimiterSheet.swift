//
//  SpeedLimiterSheet.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import SwiftUI

/// 带宽限速设置弹窗视图
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
            ZStack {
                LiquidMeshBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // 顶部说明卡片
                        LiquidGlassCard {
                            HStack(spacing: 12) {
                                Image(systemName: "speedometer")
                                    .font(.system(size: 24))
                                    .foregroundColor(LiquidTheme.cyanPrimary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("带宽平滑限速")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("限制拉取最高带宽速率，防止占用全部家庭或蜂窝网络")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }

                        // 预设档位网格
                        Text("快捷档位")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))
                            .padding(.horizontal, 4)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(presets, id: \.bytesPerSec) { preset in
                                Button {
                                    HapticManager.selection()
                                    speedLimitBytesPerSec = preset.bytesPerSec
                                    dismiss()
                                } label: {
                                    HStack {
                                        Text(preset.label)
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white)
                                        Spacer()
                                        if let current = speedLimitBytesPerSec, abs(current - preset.bytesPerSec) < 100 {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(LiquidTheme.cyanPrimary)
                                        }
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 14)
                                    .liquidGlass(
                                        cornerRadius: 14,
                                        innerTint: (speedLimitBytesPerSec ?? 0) == preset.bytesPerSec ? LiquidTheme.cyanPrimary.opacity(0.15) : Color.white.opacity(0.03)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }

                        // 自定义限速输入
                        Text("自定义限速")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))
                            .padding(.horizontal, 4)

                        LiquidGlassCard {
                            VStack(spacing: 12) {
                                HStack {
                                    TextField("输入数值 (如: 80)", text: $customValue)
                                        .keyboardType(.decimalPad)
                                        .foregroundColor(.white)
                                        .font(.system(size: 16, weight: .semibold))

                                    Picker("单位", selection: $customUnit) {
                                        Text("Mbps").tag("Mbps")
                                        Text("Gbps").tag("Gbps")
                                        Text("MB/s").tag("MB/s")
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 170)
                                }

                                LiquidGlassButton(
                                    title: "应用限速",
                                    icon: "checkmark",
                                    style: .speedCyan
                                ) {
                                    applyCustom()
                                }
                            }
                        }

                        // 解除限速按钮
                        if speedLimitBytesPerSec != nil {
                            Button {
                                HapticManager.impact(.medium)
                                speedLimitBytesPerSec = nil
                                dismiss()
                            } label: {
                                Text("解除限速（全速无限制）")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(LiquidTheme.flamePrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .liquidGlass(cornerRadius: 14, innerTint: LiquidTheme.flamePrimary.opacity(0.06))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("带宽限速设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                        .foregroundColor(.white.opacity(0.8))
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
