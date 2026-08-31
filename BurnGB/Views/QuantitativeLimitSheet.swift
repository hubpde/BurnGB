//
//  QuantitativeLimitSheet.swift
//  BurnGB
//
//  Created for BurnGB - iOS Native Edition.
//

import SwiftUI

/// 定量目标流量设置弹窗视图（标准 iOS Form 表单设计）
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
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("定量自动停止")
                                .font(.system(size: 15, weight: .semibold))
                            Text("达到目标消耗流量后，引擎将自动切断并发并触发振动通知。")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("快捷预设档位")) {
                    ForEach(presets, id: \.bytes) { preset in
                        Button {
                            HapticManager.selection()
                            targetQuota = preset.bytes
                            dismiss()
                        } label: {
                            HStack {
                                Text(preset.label)
                                    .foregroundColor(.primary)
                                Spacer()
                                if targetQuota == preset.bytes {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.orange)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                }

                Section(header: Text("自定义额度")) {
                    HStack {
                        TextField("输入数值 (如: 20)", text: $customValue)
                            .keyboardType(.decimalPad)

                        Picker("单位", selection: $customUnit) {
                            Text("MB").tag("MB")
                            Text("GB").tag("GB")
                            Text("TB").tag("TB")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 140)
                    }

                    Button("应用自定义额度") {
                        applyCustom()
                    }
                    .disabled(customValue.isEmpty)
                }

                if targetQuota != nil {
                    Section {
                        Button("清除上限（不设限制）", role: .destructive) {
                            HapticManager.impact(.medium)
                            targetQuota = nil
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("定量上限")
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
        var multiplier: Int64 = 1024 * 1024 * 1024
        if customUnit == "MB" { multiplier = 1024 * 1024 }
        else if customUnit == "TB" { multiplier = 1024 * 1024 * 1024 * 1024 }

        let bytes = Int64(num * Double(multiplier))
        targetQuota = bytes
        HapticManager.notification(.success)
        dismiss()
    }
}
