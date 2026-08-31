//
//  IPInfoView.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import SwiftUI

public struct IPInfoView: View {
    @ObservedObject private var ipService = IPDiscoveryService.shared
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidMeshBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Domestic IP Card
                        ipCard(
                            title: "国内 / 本地出口探测",
                            icon: "antenna.radiowaves.left.and.right",
                            result: ipService.localIP,
                            accentColor: LiquidTheme.emerald
                        )

                        // Cloudflare Global IP Card
                        ipCard(
                            title: "Cloudflare 全球出口探测",
                            icon: "globe.asia.australia.fill",
                            result: ipService.cloudflareIP,
                            accentColor: LiquidTheme.cyanPrimary
                        )

                        // Refresh Button
                        LiquidGlassButton(
                            title: ipService.isProbing ? "网络诊断中..." : "重新探测多出口 IP",
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
                    .padding(20)
                }
            }
            .navigationTitle("网络与多出口 IP")
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
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label(title, systemImage: icon)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    if let rtt = result?.latencyMs {
                        Text("\(rtt) ms")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(accentColor.opacity(0.15)))
                    }
                }

                Divider().background(Color.white.opacity(0.1))

                if let info = result {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(info.ip)
                                .font(.system(size: 24, weight: .heavy, design: .monospaced))
                                .foregroundColor(.white)

                            Text("\(info.isp) · \(info.asn)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))

                            Text(info.displayLocation)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }

                        Spacer()

                        Button {
                            UIPasteboard.general.string = info.ip
                            HapticManager.notification(.success)
                        } label: {
                            Image(systemName: "doc.on.doc.fill")
                                .font(.system(size: 18))
                                .foregroundColor(accentColor)
                                .padding(10)
                                .background(Circle().fill(Color.white.opacity(0.08)))
                        }
                    }
                } else {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(accentColor)
                            .padding(.vertical, 10)
                        Spacer()
                    }
                }
            }
        }
    }
}
