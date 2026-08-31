//
//  RateLimitEditorView.swift
//  BurnGB
//
//  带宽限速编辑表单。
//

import SwiftUI
import BurnGBCore

/// 带宽上限设置，内部统一保存为 Byte/s。
struct RateLimitEditorView: View {
    @Binding var bytesPerSecond: Double?
    @Environment(\.dismiss) private var dismiss
    @State private var amount = ""
    @State private var unit = "Mbps"
    @State private var message: String?

    private let presets: [(String, Double)] = [
        ("20 Mbps", 20_000_000 / 8),
        ("50 Mbps", 50_000_000 / 8),
        ("100 Mbps", 100_000_000 / 8),
        ("300 Mbps", 300_000_000 / 8),
        ("500 Mbps", 500_000_000 / 8),
        ("1 Gbps", 1_000_000_000 / 8)
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("当前限速") {
                        Text(bytesPerSecond.map { ByteFormatting.bitsPerSecond($0).text } ?? "无限制")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("快捷限速") {
                    ForEach(presets, id: \.1) { preset in
                        Button {
                            bytesPerSecond = preset.1
                            dismiss()
                        } label: {
                            HStack {
                                Text(preset.0)
                                Spacer()
                                if let value = bytesPerSecond, abs(value - preset.1) < 1 {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }

                Section("自定义限速") {
                    HStack {
                        TextField("数值", text: $amount)
                            .keyboardType(.decimalPad)
                        Picker("单位", selection: $unit) {
                            Text("Mbps").tag("Mbps")
                            Text("Gbps").tag("Gbps")
                            Text("MB/s").tag("MB/s")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 170)
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

                if bytesPerSecond != nil {
                    Section {
                        Button("解除限速", role: .destructive) {
                            bytesPerSecond = nil
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
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func applyCustom() {
        guard let number = Double(amount), number.isFinite, number > 0 else {
            message = "请输入大于 0 的有限数字。"
            return
        }
        let value: Double
        switch unit {
        case "Mbps": value = number * 1_000_000 / 8
        case "Gbps": value = number * 1_000_000_000 / 8
        default: value = number * 1024 * 1024
        }
        guard value.isFinite, value > 0 else {
            message = "限速值无效。"
            return
        }
        bytesPerSecond = value
        dismiss()
    }
}
