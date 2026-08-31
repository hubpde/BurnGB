//
//  SpeedLimiterSheet.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import SwiftUI

public struct SpeedLimiterSheet: View {
    @Binding public var speedLimitBytesPerSec: Double?
    @Environment(\.dismiss) private var dismiss

    @State private var customValue: String = ""
    @State private var customUnit: String = "Mbps"

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
                    VStack(alignment: .leading, spacing: 20) {
                        // Info Header Card
                        LiquidGlassCard {
                            HStack(spacing: 12) {
                                Image(systemName: "speedometer")
                                    .font(.system(size: 26))
                                    .foregroundColor(LiquidTheme.cyanPrimary)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("带宽限速控制")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("限制并发下载的最高速率，防止占用全部家庭或蜂窝带宽")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.65))
                                }
                            }
                        }

                        // Presets Grid
                        Text("快捷预设")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 4)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(presets, id: \.bytesPerSec) { preset in
                                Button {
                                    HapticManager.selection()
                                    speedLimitBytesPerSec = preset.bytesPerSec
                                    dismiss()
                                } label: {
                                    HStack {
                                        Text(preset.label)
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white)
                                        Spacer()
                                        if let current = speedLimitBytesPerSec, abs(current - preset.bytesPerSec) < 100 {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(LiquidTheme.cyanPrimary)
                                        }
                                    }
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 16)
                                    .liquidGlass(
                                        cornerRadius: 16,
                                        innerTint: (speedLimitBytesPerSec ?? 0) == preset.bytesPerSec ? LiquidTheme.cyanPrimary.opacity(0.18) : Color.white.opacity(0.04),
                                        glowColor: (speedLimitBytesPerSec ?? 0) == preset.bytesPerSec ? LiquidTheme.cyanPrimary : nil
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }

                        // Custom Input Card
                        Text("自定义限速")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 4)
                            .padding(.top, 8)

                        LiquidGlassCard {
                            VStack(spacing: 14) {
                                HStack {
                                    TextField("输入数值 (如: 80)", text: $customValue)
                                        .keyboardType(.decimalPad)
                                        .foregroundColor(.white)
                                        .font(.system(size: 18, weight: .semibold))

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
                                    icon: "arrow.right.circle.fill",
                                    style: .speedCyan
                                ) {
                                    applyCustom()
                                }
                            }
                        }

                        // Unlimited Button
                        if speedLimitBytesPerSec != nil {
                            Button {
                                HapticManager.impact(.medium)
                                speedLimitBytesPerSec = nil
                                dismiss()
                            } label: {
                                Text("解除限速 (最高全速狂飙)")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(LiquidTheme.flamePrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .liquidGlass(cornerRadius: 16, innerTint: LiquidTheme.flamePrimary.opacity(0.08))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(20)
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
