//
//  AboutView.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import SwiftUI

public struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidMeshBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        // App Icon & Hero
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(LiquidTheme.burningGradient)
                                    .frame(width: 84, height: 84)
                                    .shadow(color: LiquidTheme.flamePrimary.opacity(0.6), radius: 16, x: 0, y: 8)

                                Image(systemName: "flame.fill")
                                    .font(.system(size: 44, weight: .heavy))
                                    .foregroundColor(.white)
                            }

                            Text("BurnGB")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)

                            Text("iOS 26 Liquid Glass Edition · v1.0.0")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.top, 16)

                        // Feature Highlights
                        LiquidGlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("功能特性")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)

                                featureRow(icon: "bolt.fill", title: "多线程流式拉取", desc: "最高支持 64 线程全速并发，零内存增长")
                                featureRow(icon: "gauge.with.needle.fill", title: "智能定量与限速", desc: "设定额度自动切断，支持带宽阶梯限速")
                                featureRow(icon: "sparkles", title: "全原生 iOS 26 液态玻璃", desc: "超细腻流体光泽反射、高斯材质与触感反馈")
                                featureRow(icon: "iphone.gen3", title: "灵动岛全场景适配", desc: "锁屏实时活动、紧凑/极简/展开岛屿全覆盖")
                                featureRow(icon: "moon.stars.fill", title: "熄屏后台长效保活", desc: "静音引擎加持，锁屏持续拉取不中断")
                            }
                        }

                        // Disclaimer
                        LiquidGlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("免责声明")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.red.opacity(0.9))

                                Text("本应用仅供开发者网络基准性能测试、带宽吞吐量排查与套餐流量消耗自用。请勿用于未授权压测、破坏性流量攻击或其他违规用途。使用本工具产生的一切流量资费及后果由使用者自行承担。")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.65))
                                    .lineSpacing(4)
                            }
                        }

                        // Credits
                        Text("Repository: hubpde/BurnGB\nCrafted with Pure SwiftUI & Swift Concurrency")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 20)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }

    @ViewBuilder
    private func featureRow(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(LiquidTheme.cyanPrimary)
                .frame(width: 24)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.55))
            }
        }
    }
}
