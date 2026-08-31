//
//  IPDiagnosticsView.swift
//  BurnGB
//
//  多出口公网 IP 与节点延时诊断。
//

import SwiftUI
import BurnGBCore

/// 网络诊断页：只做小探针请求，不把测速文件用于 IP 查询。
struct IPDiagnosticsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        List {
            Section {
                Button {
                    model.checkEgress()
                } label: {
                    HStack {
                        Label("检查公网出口", systemImage: "network")
                        Spacer()
                        if model.isCheckingEgress {
                            ProgressView()
                        }
                    }
                }
                .disabled(model.isCheckingEgress)
            } header: {
                Text("公网出口")
            } footer: {
                Text("结果来自轻量公网探针，仅用于了解不同网络出口；不会把探针响应当作流量消耗。")
            }

            if model.egressResults.isEmpty {
                Section {
                    ContentUnavailableView(
                        "尚未检查",
                        systemImage: "network.slash",
                        description: Text("点击上方按钮探测当前网络出口。")
                    )
                }
            } else {
                Section("出口结果") {
                    ForEach(model.egressResults) { result in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(result.ipAddress)
                                    .font(.headline.monospaced())
                                    .textSelection(.enabled)
                                Spacer()
                                if let latency = result.latencyMilliseconds {
                                    Text("\(latency) ms")
                                        .font(.subheadline.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Text(result.provider)
                                .font(.subheadline)
                            Text("\(result.location) · 来源 \(result.source)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }

            Section("节点延时") {
                Button {
                    model.probeAllNodes()
                } label: {
                    HStack {
                        Label("测量全部节点", systemImage: "waveform.path.ecg")
                        Spacer()
                        if model.isProbingNodes {
                            ProgressView()
                        }
                    }
                }
                .disabled(model.isProbingNodes)

                ForEach(model.nodes) { node in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(node.name)
                            Text(node.urlString)
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        if let result = model.probeResults[node.id] {
                            Text(result.latencyMilliseconds.map { "\($0) ms" } ?? "失败")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(result.isReachable ? .secondary : .red)
                        }
                    }
                }
            }
        }
        .navigationTitle("诊断")
        .onAppear {
            if model.egressResults.isEmpty {
                model.checkEgress()
            }
        }
    }
}
