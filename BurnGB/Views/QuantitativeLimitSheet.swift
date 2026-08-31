//
//  QuantitativeLimitSheet.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import SwiftUI

/// 定量目标流量设置弹窗视图
public struct QuantitativeLimitSheet: View {
    @Binding public var targetQuota: Int64?
    @Environment(\.dismiss) private var dismiss

    @State private var customValue: String = ""
    @State private var customUnit: String = "GB"

    /// 常用快捷预设档位
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
                    VStack(alignment: .leading, spacing: 18) {
                        // 顶部说明卡片
                        LiquidGlassCard {
                            HStack(spacing: 12) {
                                Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                                    .font(.system(size: 24))
                                    .foregroundColor(LiquidTheme.flamePrimary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("定量自动切断")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("达到目标消耗流量后，引擎将自动切断并发并触发振动通知")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }

                        // 快捷预设网格
                        Text("快捷档位")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))
                            .padding(.horizontal, 4)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(presets, id: \.bytes) { preset in
                                Button {
                                    HapticManager.selection()
                                    targetQuota = preset.bytes
                                    dismiss()
                                } label: {
                                    HStack {
                                        Text(preset.label)
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white)
                                        Spacer()
                                        if targetQuota == preset.bytes {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(LiquidTheme.flamePrimary)
                                        }
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 14)
                                    .liquidGlass(
                                        cornerRadius: 14,
                                        innerTint: targetQuota == preset.bytes ? LiquidTheme.flamePrimary.opacity(0.15) : Color.white.opacity(0.03)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }

                        // 自定义输入卡片
                        Text("自定义数值")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))
                            .padding(.horizontal, 4)

                        LiquidGlassCard {
                            VStack(spacing: 12) {
                                HStack {
                                    TextField("输入数字 (如: 20)", text: $customValue)
                                        .keyboardType(.decimalPad)
                                        .foregroundColor(.white)
                                        .font(.system(size: 16, weight: .semibold))

                                    Picker("单位", selection: $customUnit) {
                                        Text("MB").tag("MB")
                                        Text("GB").tag("GB")
                                        Text("TB").tag("TB")
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 140)
                                }

                                LiquidGlassButton(
                                    title: "应用设定",
                                    icon: "checkmark",
                                    style: .burning
                                ) {
                                    applyCustom()
                                }
                            }
                        }

                        // 清除上限按钮
                        if targetQuota != nil {
                            Button {
                                HapticManager.impact(.medium)
                                targetQuota = nil
                                dismiss()
                            } label: {
                                Text("清除上限（不设限制）")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.red.opacity(0.85))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .liquidGlass(cornerRadius: 14, innerTint: Color.red.opacity(0.06))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("定量上限设置")
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
