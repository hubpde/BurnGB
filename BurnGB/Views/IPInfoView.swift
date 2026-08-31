//
//  IPInfoView.swift
//  BurnGB
//
//  Created for BurnGB - iOS Native Edition.
//

import SwiftUI

/// 多出口公网 IP 与路由归属地诊断视图（标准 iOS Form 表单设计）
public struct IPInfoView: View {
    @ObservedObject private var ipService = IPDiscoveryService.shared
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                // 国内直连出口
                Section(header: Text("国内 / 本地出口")) {
                    if let info = ipService.localIP {
                        ipContentRow(info: info, tagColor: .green)
                    } else {
                        HStack {
                            Text("探测中...")
                                .foregroundColor(.secondary)
                            Spacer()
                            ProgressView()
                        }
                    }
                }

                // Cloudflare 全球出口
                Section(header: Text("Cloudflare 全球出口")) {
                    if let info = ipService.cloudflareIP {
                        ipContentRow(info: info, tagColor: .blue)
                    } else {
                        HStack {
                            Text("探测中...")
                                .foregroundColor(.secondary)
                            Spacer()
                            ProgressView()
                        }
                    }
                }

                // 操作区
                Section {
                    Button {
                        Task {
                            await ipService.probeAll()
                            HapticManager.notification(.success)
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Label(ipService.isProbing ? "诊断探测中..." : "重新探测多出口 IP", systemImage: "arrow.clockwise")
                            Spacer()
                        }
                    }
                    .disabled(ipService.isProbing)
                }
            }
            .navigationTitle("网络与出口 IP")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .onAppear {
                if ipService.localIP == nil && ipService.cloudflareIP == nil {
                    Task {
                        await ipService.probeAll()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func ipContentRow(info: IPProbeResult, tagColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(info.ip)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                Spacer()
                Button {
                    UIPasteboard.general.string = info.ip
                    HapticManager.notification(.success)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.borderless)
            }

            HStack {
                Text("\(info.isp) · \(info.asn)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Spacer()
                if let rtt = info.latencyMs {
                    Text("\(rtt) ms")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(tagColor)
                }
            }

            Text(info.displayLocation)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
