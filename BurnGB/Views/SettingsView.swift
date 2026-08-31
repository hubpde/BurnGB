//
//  SettingsView.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import SwiftUI

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
                    VStack(alignment: .leading, spacing: 22) {
                        // Background & Dynamic Island Section
                        Text("后台与灵动岛")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 4)

                        LiquidGlassCard {
                            VStack(spacing: 16) {
                                Toggle(isOn: $engine.enableBackgroundExecution) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("后台持续消耗")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("锁屏或切到其他应用时维持最大带宽拉取")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }
                                .tint(LiquidTheme.flamePrimary)
                                .onChange(of: engine.enableBackgroundExecution) { val in
                                    UserDefaults.standard.set(val, forKey: "burn_bg_exec")
                                }

                                Divider().background(Color.white.opacity(0.1))

                                Toggle(isOn: $engine.enableLiveActivity) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("灵动岛与实时活动")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("在灵动岛与锁屏通知栏实时监控流量与速率")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }
                                .tint(LiquidTheme.cyanPrimary)
                            }
                        }

                        // Display Performance Section
                        Text("性能与显示")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 4)

                        LiquidGlassCard {
                            VStack(spacing: 14) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("ProMotion 120Hz 全局高刷支持")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("已开启 CADisableMinimumFrameDurationOnPhone")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    Spacer()
                                    Image(systemName: "bolt.badge.checkmark.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(LiquidTheme.emerald)
                                }

                                Divider().background(Color.white.opacity(0.1))

                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("内存零分配引擎")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("流式丢弃字节分块，消耗 1TB 内存亦无增长")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    Spacer()
                                    Image(systemName: "memorychip.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(LiquidTheme.cyanPrimary)
                                }
                            }
                        }

                        // About Navigation
                        LiquidGlassCard {
                            Button {
                                showAbout = true
                            } label: {
                                HStack {
                                    Label("关于 BurnGB 与免责声明", systemImage: "info.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.4))
                                }
                            }
                        }
                    }
                    .padding(20)
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
