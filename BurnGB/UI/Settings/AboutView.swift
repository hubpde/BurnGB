//
//  AboutView.swift
//  BurnGB
//
//  关于、权限边界与使用说明。
//

import SwiftUI

/// 关于页面，主动说明后台与流量统计的系统边界。
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: "flame.fill")
                            .font(.title)
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading) {
                            Text("BurnGB")
                                .font(.title2.weight(.semibold))
                            Text("原生 iOS 26 网络流量工具")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section("使用边界") {
                    Text("请只使用自己拥有或明确获授权的 HTTPS 测速端点。BurnGB 面向个人带宽验证、网络故障排查和流量消耗测试，不用于未授权压测或破坏性流量行为。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("后台与实时活动") {
                    Text("iOS 26 的 BGContinuedProcessingTask 和后台 URLSession 都由系统管理，可能排队、延迟、过期或终止。实时活动只负责展示状态，不负责维持网络任务；频繁更新资格也不等同于每秒更新保证。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("实现") {
                    LabeledContent("界面", value: "SwiftUI + Liquid Glass")
                    LabeledContent("网络", value: "Swift Concurrency + URLSession")
                    LabeledContent("动态岛", value: "ActivityKit")
                    LabeledContent("仓库", value: "hubpde/BurnGB")
                }
            }
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
