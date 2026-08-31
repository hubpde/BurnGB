//
//  AboutView.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import SwiftUI

/// 关于与免责声明视图
public struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidMeshBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // 图标与版本
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(LiquidTheme.burningGradient)
                                    .frame(width: 76, height: 76)
                                    .shadow(color: LiquidTheme.flamePrimary.opacity(0.35), radius: 12, x: 0, y: 6)

                                Image(systemName: "flame.fill")
                                    .font(.system(size: 38, weight: .heavy))
                                    .foregroundColor(.white)
                            }

                            Text("BurnGB")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("iOS 26 Liquid Glass Edition · v1.0.0")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        .padding(.top, 12)

                        // 核心特性列表
                        LiquidGlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("功能特性")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)

                                featureRow(icon: "bolt.fill", title: "多线程流式并发", desc: "最高支持 64 线程全速并发，零内存增长杜绝 OOM")
                                featureRow(icon: "gauge.with.needle.fill", title: "智能定量与限速", desc: "设定额度自动切断，支持带宽阶梯限速平滑控流")
                                featureRow(icon: "sparkles", title: "全原生 iOS 26 液态玻璃", desc: "极简磨砂质感、微光折射边框与触感反馈")
                                featureRow(icon: "iphone.gen3", title: "灵动岛全形态适配", desc: "紧凑、极简、展开形态及锁屏实时活动全覆盖")
                                featureRow(icon: "moon.stars.fill", title: "熄屏后台长效保活", desc: "静音音频引擎无感常驻，锁屏持续拉取不中断")
                            }
                        }

                        // 免责声明
                        LiquidGlassCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("免责声明")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.red.opacity(0.9))

                                Text("本应用仅供开发者网络基准性能测试、带宽吞吐量排查与套餐流量消耗自用。请勿用于未授权压测、破坏性流量攻击或其他违规用途。使用本工具产生的一切流量资费及后果由使用者自行承担。")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.6))
                                    .lineSpacing(3)
                            }
                        }

                        // 开源署名
                        Text("Repository: hubpde/BurnGB\nCrafted with Pure SwiftUI & Swift Concurrency")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.35))
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 16)
                    }
                    .padding(18)
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
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(LiquidTheme.cyanPrimary)
                .frame(width: 20)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
}
