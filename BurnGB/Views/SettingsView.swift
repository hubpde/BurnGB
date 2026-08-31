//
//  SettingsView.swift
//  BurnGB
//
//  Created for BurnGB - iOS Native Edition.
//

import SwiftUI

/// 系统偏好与性能设置视图（标准 iOS Form 表单设计）
public struct SettingsView: View {
    @ObservedObject private var engine = BurnEngine.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showAbout = false

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                // 实时活动与灵动岛
                Section(header: Text("灵动岛与实时活动"), footer: Text("点火拉取时自动在灵动岛（紧凑/极简/展开）及锁屏界面高频更新实时网速与用量。")) {
                    Toggle("启用灵动岛实时活动", isOn: $engine.enableLiveActivity)
                        .tint(.orange)
                        .onChange(of: engine.enableLiveActivity) { val in
                            UserDefaults.standard.set(val, forKey: "burn_live_activity")
                        }
                }

                // 性能与架构
                Section(header: Text("底层特性")) {
                    HStack {
                        Text("ProMotion 120Hz 高刷支持")
                        Spacer()
                        Text("已开启")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("内存零增长引擎")
                        Spacer()
                        Text("~15 MB")
                            .foregroundColor(.secondary)
                    }
                }

                // 关于
                Section {
                    Button {
                        showAbout = true
                    } label: {
                        HStack {
                            Text("关于 BurnGB 与免责声明")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
        }
    }
}
