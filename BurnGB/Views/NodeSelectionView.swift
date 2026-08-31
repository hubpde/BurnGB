//
//  NodeSelectionView.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import SwiftUI

public struct NodeSelectionView: View {
    @Binding public var currentNode: BurnNode
    @Environment(\.dismiss) private var dismiss

    @State private var customNodes: [BurnNode] = []
    @State private var isPingingAll = false
    @State private var pingResults: [UUID: Int] = [:]

    @State private var showAddSheet = false
    @State private var newName = ""
    @State private var newUrl = ""
    @State private var isCheckingUrl = false
    @State private var urlError: String?

    public init(currentNode: Binding<BurnNode>) {
        self._currentNode = currentNode
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LiquidMeshBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        // Top Ping Action
                        HStack {
                            Text("测速节点选择")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))

                            Spacer()

                            Button {
                                pingAllNodes()
                            } label: {
                                HStack(spacing: 6) {
                                    if isPingingAll {
                                        ProgressView()
                                            .tint(LiquidTheme.cyanPrimary)
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "waveform.path.ecg")
                                    }
                                    Text(isPingingAll ? "测延时中..." : "全节点测延时")
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(LiquidTheme.cyanPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .liquidGlass(cornerRadius: 12, innerTint: LiquidTheme.cyanPrimary.opacity(0.12))
                            }
                            .disabled(isPingingAll)
                        }
                        .padding(.horizontal, 4)

                        // Preset Groups
                        let groups = Dictionary(grouping: NodePresetManager.defaultNodes, by: { $0.group })
                        ForEach(groups.keys.sorted(), id: \.self) { groupName in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(groupName)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.leading, 4)

                                ForEach(groups[groupName] ?? []) { node in
                                    nodeRow(node)
                                }
                            }
                        }

                        // Custom Nodes Section
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("自定义节点")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.leading, 4)

                                Spacer()

                                Button {
                                    showAddSheet = true
                                } label: {
                                    Label("添加节点", systemImage: "plus.circle.fill")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(LiquidTheme.flamePrimary)
                                }
                            }

                            if customNodes.isEmpty {
                                LiquidGlassCard {
                                    HStack {
                                        Spacer()
                                        VStack(spacing: 6) {
                                            Image(systemName: "link.badge.plus")
                                                .font(.system(size: 24))
                                                .foregroundColor(.white.opacity(0.3))
                                            Text("暂无自定义节点，点击右上角添加")
                                                .font(.system(size: 13))
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 10)
                                }
                            } else {
                                ForEach(customNodes) { node in
                                    nodeRow(node)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("选择测速节点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .sheet(isPresented: $showAddSheet) {
                addNodeSheet
            }
            .onAppear {
                loadCustomNodes()
            }
        }
    }

    @ViewBuilder
    private func nodeRow(_ node: BurnNode) -> some View {
        Button {
            HapticManager.selection()
            currentNode = node
            dismiss()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: node.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(currentNode.id == node.id ? LiquidTheme.cyanPrimary : .white.opacity(0.7))
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 3) {
                    Text(node.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text(node.urlString)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.45))
                        .lineLimit(1)
                }

                Spacer()

                if let ping = pingResults[node.id] {
                    Text("\(ping) ms")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(ping < 80 ? LiquidTheme.emerald : (ping < 200 ? LiquidTheme.flameSecondary : Color.red.opacity(0.8)))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(Color.black.opacity(0.3))
                        )
                }

                if currentNode.id == node.id {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(LiquidTheme.cyanPrimary)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .liquidGlass(
                cornerRadius: 18,
                innerTint: currentNode.id == node.id ? LiquidTheme.cyanPrimary.opacity(0.15) : Color.white.opacity(0.04),
                glowColor: currentNode.id == node.id ? LiquidTheme.cyanPrimary : nil
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var addNodeSheet: some View {
        NavigationStack {
            ZStack {
                LiquidMeshBackground()

                VStack(alignment: .leading, spacing: 20) {
                    LiquidGlassCard {
                        VStack(spacing: 14) {
                            TextField("节点名称 (如: 私有高速镜像)", text: $newName)
                                .foregroundColor(.white)

                            Divider().background(Color.white.opacity(0.1))

                            TextField("URL 地址 (支持 HTTP/HTTPS)", text: $newUrl)
                                .keyboardType(.URL)
                                .textInputAutocapitalization(.never)
                                .foregroundColor(.white)
                        }
                    }

                    if let error = urlError {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.red.opacity(0.9))
                            .padding(.horizontal, 4)
                    }

                    LiquidGlassButton(
                        title: isCheckingUrl ? "连通性检测中..." : "保存并启用节点",
                        icon: "checkmark.seal.fill",
                        style: .burning
                    ) {
                        saveCustomNode()
                    }
                    .disabled(isCheckingUrl || newName.isEmpty || newUrl.isEmpty)

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("添加自定义节点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showAddSheet = false }
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }

    private func pingAllNodes() {
        isPingingAll = true
        let allNodes = NodePresetManager.defaultNodes + customNodes
        Task {
            for node in allNodes {
                if let url = node.url {
                    let rtt = await IPDiscoveryService.shared.pingNode(url)
                    await MainActor.run {
                        if let rtt = rtt {
                            pingResults[node.id] = rtt
                        }
                    }
                }
            }
            await MainActor.run {
                isPingingAll = false
                HapticManager.notification(.success)
            }
        }
    }

    private func saveCustomNode() {
        guard let url = URL(string: newUrl), url.scheme == "http" || url.scheme == "https" else {
            urlError = "请输入正确的 http:// 或 https:// 链接"
            return
        }

        isCheckingUrl = true
        urlError = nil

        Task {
            let rtt = await IPDiscoveryService.shared.pingNode(url)
            await MainActor.run {
                isCheckingUrl = false
                if rtt == nil {
                    urlError = "警告：此 URL 响应异常或无法连接，请确认服务是否正常"
                }

                let node = BurnNode(
                    name: newName,
                    urlString: newUrl,
                    group: "自定义",
                    iconName: "link.circle.fill",
                    isCustom: true,
                    lastPingMs: rtt
                )

                customNodes.append(node)
                saveCustomNodes()
                currentNode = node
                showAddSheet = false
                HapticManager.notification(.success)
            }
        }
    }

    private func loadCustomNodes() {
        if let data = UserDefaults.standard.data(forKey: "burn_custom_nodes"),
           let decoded = try? JSONDecoder().decode([BurnNode].self, from: data) {
            self.customNodes = decoded
        }
    }

    private func saveCustomNodes() {
        if let encoded = try? JSONEncoder().encode(customNodes) {
            UserDefaults.standard.set(encoded, forKey: "burn_custom_nodes")
        }
    }
}
