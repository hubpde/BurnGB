//
//  QuotaEditorView.swift
//  BurnGB
//
//  定量上限编辑表单。
//

import SwiftUI
import BurnGBCore

/// 定量上限设置。所有值在保存前都进行有限值和溢出校验。
struct QuotaEditorView: View {
    @Binding var quotaBytes: Int64?
    @Environment(\.dismiss) private var dismiss
    @State private var amount = ""
    @State private var unit = "GB"
    @State private var message: String?

    private let presets: [(String, Int64)] = [
        ("500 MB", 500 * 1024 * 1024),
        ("1 GB", 1024 * 1024 * 1024),
        ("5 GB", 5 * 1024 * 1024 * 1024),
        ("10 GB", 10 * 1024 * 1024 * 1024),
        ("50 GB", 50 * 1024 * 1024 * 1024),
        ("100 GB", 100 * 1024 * 1024 * 1024)
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("当前上限") {
                        Text(quotaBytes.map { ByteFormatting.bytes($0).text } ?? "无限制")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("快捷额度") {
                    ForEach(presets, id: \.1) { preset in
                        Button {
                            quotaBytes = preset.1
                            dismiss()
                        } label: {
                            HStack {
                                Text(preset.0)
                                Spacer()
                                if quotaBytes == preset.1 {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }
                }

                Section("自定义额度") {
                    HStack {
                        TextField("数值", text: $amount)
                            .keyboardType(.decimalPad)
                        Picker("单位", selection: $unit) {
                            Text("MB").tag("MB")
                            Text("GB").tag("GB")
                            Text("TB").tag("TB")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 140)
                    }
                    Button("应用") { applyCustom() }
                        .disabled(amount.isEmpty)
                }

                if let message {
                    Section {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                if quotaBytes != nil {
                    Section {
                        Button("清除上限", role: .destructive) {
                            quotaBytes = nil
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
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func applyCustom() {
        guard let number = Double(amount), number.isFinite, number > 0 else {
            message = "请输入大于 0 的有限数字。"
            return
        }
        let multiplier: Double
        switch unit {
        case "MB": multiplier = 1024 * 1024
        case "TB": multiplier = 1024 * 1024 * 1024 * 1024
        default: multiplier = 1024 * 1024 * 1024
        }
        guard number <= Double(Int64.max) / multiplier else {
            message = "额度过大，超出系统可表示范围。"
            return
        }
        quotaBytes = Int64(number * multiplier)
        dismiss()
    }
}
