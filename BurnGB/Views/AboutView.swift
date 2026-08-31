//
//  AboutView.swift
//  BurnGB
//
//  Created for BurnGB - iOS Native Edition.
//

import SwiftUI

/// 关于与免责声明视图（标准 iOS Form 表单设计）
public struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                // 应用图标与版本信息
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 44, weight: .bold))
                                .foregroundColor(.orange)
                            Text("BurnGB")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                            Text("iOS Native Edition · v1.0.0")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                        Spacer()
                    }
                }

                // 核心功能特性
                Section(header: Text("核心特性")) {
                    featureRow(title: "多线程流式并发", desc: "最高支持 64 线程全速并发，零内存增长杜绝 OOM。")
                    featureRow(title: "智能定量与限速", desc: "设定额度自动切断，支持带宽阶梯限速平滑控流。")
                    featureRow(title: "官方实时活动", desc: "紧凑、极简、展开灵动岛形态及锁屏实时活动全覆盖。")
                    featureRow(title: "多出口网络诊断", desc: "国内直连出口与 Cloudflare 全球出口快速探测与测延时。")
                }

                // 免责声明
                Section(header: Text("免责声明")) {
                    Text("本应用仅供开发者网络基准性能测试、带宽吞吐量排查与套餐流量消耗自用。请勿用于未授权压测、破坏性流量攻击或其他违规用途。使用本工具产生的一切流量资费及后果由使用者自行承担。")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                // 开源信息
                Section {
                    HStack {
                        Text("代码仓库")
                        Spacer()
                        Text("hubpde/BurnGB")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func featureRow(title: String, desc: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
            Text(desc)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}
