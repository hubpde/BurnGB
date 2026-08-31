//
//  IPInfoView.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import SwiftUI

/// 多出口公网 IP 与路由归属地诊断视图
public struct IPInfoView: View {
    @ObservedObject private var ipService = IPDiscoveryService.shared
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidMeshBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // 国内/本地直连出口卡片
                        ipCard(
                            title: "国内 / 本地出口探测",
                            icon: "antenna.radiowaves.left.and.right",
                            result: ipService.localIP,
                            accentColor: LiquidTheme.emerald
                        )

                        // Cloudflare 全球出口卡片
                        ipCard(
                            title: "Cloudflare 全球出口探测",
                            icon: "globe.asia.australia.fill",
                            result: ipService.cloudflareIP,
                            accentColor: LiquidTheme.cyanPrimary
                        )

                        // 重新诊断按钮
                        LiquidGlassButton(
                            title: ipService.isProbing ? "诊断探测中..." : "重新探测多出口 IP",
                            icon: "arrow.clockwise",
                            style: .speedCyan
                        ) {
                            Task {
                                await ipService.probeAll()
                                HapticManager.notification(.success)
                            }
                        }
                        .disabled(ipService.isProbing)
                    }
                    .padding(18)
                }
            }
            .navigationTitle("网络与出口 IP")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                        .foregroundColor(.white.opacity(0.8))
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
    private func ipCard(
        title: String,
        icon: String,
        result: IPProbeResult?,
        accentColor: Color
    ) -> some View {
        LiquidGlassCard(glowColor: accentColor) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(title, systemImage: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    if let rtt = result?.latencyMs {
                        Text("\(rtt) ms")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(accentColor)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(accentColor.opacity(0.12)))
                    }
                }

                Divider().background(Color.white.opacity(0.08))

                if let info = result {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(info.ip)
                                .font(.system(size: 22, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)

                            Text("\(info.isp) · \(info.asn)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.65))

                            Text(info.displayLocation)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.45))
                        }

                        Spacer()

                        Button {
                            UIPasteboard.general.string = info.ip
                            HapticManager.notification(.success)
                        } label: {
                            Image(systemName: "doc.on.doc.fill")
                                .font(.system(size: 16))
                                .foregroundColor(accentColor)
                                .padding(9)
                                .background(Circle().fill(Color.white.opacity(0.06)))
                        }
                    }
                } else {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(accentColor)
                            .padding(.vertical, 8)
                        Spacer()
                    }
                }
            }
        }
    }
}
