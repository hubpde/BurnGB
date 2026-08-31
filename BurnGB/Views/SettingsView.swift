//
//  SettingsView.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import SwiftUI

/// 系统偏好与性能设置视图
public struct SettingsView: View {
    @ObservedObject private var engine = BurnEngine.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showAbout = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidMeshBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 后台与灵动岛配置
                        Text("后台与灵动岛")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))
                            .padding(.horizontal, 4)

                        LiquidGlassCard {
                            VStack(spacing: 14) {
                                Toggle(isOn: $engine.enableBackgroundExecution) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("后台长效保活")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("锁屏或切到其他应用时维持音频会话，持续全速拉取")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.55))
                                    }
                                }
                                .tint(LiquidTheme.flamePrimary)
                                .onChange(of: engine.enableBackgroundExecution) { val in
                                    UserDefaults.standard.set(val, forKey: "burn_bg_exec")
                                }

                                Divider().background(Color.white.opacity(0.08))

                                Toggle(isOn: $engine.enableLiveActivity) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("灵动岛与锁屏活动")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("在灵动岛（紧凑/极简/展开）及锁屏实时掌控速率与用量")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.55))
                                    }
                                }
                                .tint(LiquidTheme.cyanPrimary)
                            }
                        }

                        // 性能与显示
                        Text("底层特性")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))
                            .padding(.horizontal, 4)

                        LiquidGlassCard {
                            VStack(spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("ProMotion 120Hz 高刷调度")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("启用 CADisableMinimumFrameDurationOnPhone")
                                            .font(.system(size: 11))
                                            .foregroundColor(.white.opacity(0.55))
                                    }
                                    Spacer()
                                    Image(systemName: "bolt.badge.checkmark.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(LiquidTheme.emerald)
                                }

                                Divider().background(Color.white.opacity(0.08))

                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("零内存增长架构")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("流式分块统计即刻丢弃，内存稳定维持在 ~15MB")
                                            .font(.system(size: 11))
                                            .foregroundColor(.white.opacity(0.55))
                                    }
                                    Spacer()
                                    Image(systemName: "memorychip.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(LiquidTheme.cyanPrimary)
                                }
                            }
                        }

                        // 关于导航
                        LiquidGlassCard {
                            Button {
                                showAbout = true
                            } label: {
                                HStack {
                                    Label("关于 BurnGB 与免责声明", systemImage: "info.circle.fill")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                            }
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("设置与偏好")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
        }
    }
}
