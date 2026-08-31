//
//  QuantitativeLimitSheet.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import SwiftUI

public struct QuantitativeLimitSheet: View {
    @Binding public var targetQuota: Int64?
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPresetGB: Double? = nil
    @State private var customValue: String = ""
    @State private var customUnit: String = "GB"

    private let presets: [(label: String, bytes: Int64)] = [
        ("500 MB", 500 * 1024 * 1024),
        ("1 GB", 1024 * 1024 * 1024),
        ("2 GB", 2 * 1024 * 1024 * 1024),
        ("5 GB", 5 * 1024 * 1024 * 1024),
        ("10 GB", 10 * 1024 * 1024 * 1024),
        ("50 GB", 50 * 1024 * 1024 * 1024),
        ("100 GB", 100 * 1024 * 1024 * 1024),
        ("500 GB", 500 * 1024 * 1024 * 1024)
    ]

    public init(targetQuota: Binding<Int64?>) {
        self._targetQuota = targetQuota
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
                                Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                                    .font(.system(size: 26))
                                    .foregroundColor(LiquidTheme.flamePrimary)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("定量自动停止")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("达到目标消耗流量后，引擎将自动停止并触发振动通知")
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
                            ForEach(presets, id: \.bytes) { preset in
                                Button {
                                    HapticManager.selection()
                                    targetQuota = preset.bytes
                                    dismiss()
                                } label: {
                                    HStack {
                                        Text(preset.label)
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white)
                                        Spacer()
                                        if targetQuota == preset.bytes {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(LiquidTheme.flamePrimary)
                                        }
                                    }
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 16)
                                    .liquidGlass(
                                        cornerRadius: 16,
                                        innerTint: targetQuota == preset.bytes ? LiquidTheme.flamePrimary.opacity(0.18) : Color.white.opacity(0.04),
                                        glowColor: targetQuota == preset.bytes ? LiquidTheme.flamePrimary : nil
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }

                        // Custom Input Card
                        Text("自定义额度")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 4)
                            .padding(.top, 8)

                        LiquidGlassCard {
                            VStack(spacing: 14) {
                                HStack {
                                    TextField("输入数字 (如: 20)", text: $customValue)
                                        .keyboardType(.decimalPad)
                                        .foregroundColor(.white)
                                        .font(.system(size: 18, weight: .semibold))

                                    Picker("单位", selection: $customUnit) {
                                        Text("MB").tag("MB")
                                        Text("GB").tag("GB")
                                        Text("TB").tag("TB")
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 140)
                                }

                                LiquidGlassButton(
                                    title: "应用自定义额度",
                                    icon: "arrow.right.circle.fill",
                                    style: .burning
                                ) {
                                    applyCustom()
                                }
                            }
                        }

                        // Clear Button
                        if targetQuota != nil {
                            Button {
                                HapticManager.impact(.medium)
                                targetQuota = nil
                                dismiss()
                            } label: {
                                Text("清除上限 (不设限制)")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.red.opacity(0.9))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .liquidGlass(cornerRadius: 16, innerTint: Color.red.opacity(0.08))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("设置定量上限")
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
        var multiplier: Int64 = 1024 * 1024 * 1024
        if customUnit == "MB" { multiplier = 1024 * 1024 }
        else if customUnit == "TB" { multiplier = 1024 * 1024 * 1024 * 1024 }

        let bytes = Int64(num * Double(multiplier))
        targetQuota = bytes
        HapticManager.notification(.success)
        dismiss()
    }
}
