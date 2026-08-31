//
//  NodeSelectionView.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import SwiftUI

/// 测速与拉取节点切换及延时探测视图
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
                    VStack(alignment: .leading, spacing: 20) {
                        // 顶部测延时按钮
                        HStack {
                            Text("测速节点")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.75))

                            Spacer()

                            Button {
                                pingAllNodes()
                            } label: {
                                HStack(spacing: 5) {
                                    if isPingingAll {
                                        ProgressView()
                                            .tint(LiquidTheme.cyanPrimary)
                                            .scaleEffect(0.75)
                                    } else {
                                        Image(systemName: "waveform.path.ecg")
                                    }
                                    Text(isPingingAll ? "测量中..." : "全节点测延时")
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(LiquidTheme.cyanPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .liquidGlass(cornerRadius: 10, innerTint: LiquidTheme.cyanPrimary.opacity(0.1))
                            }
                            .disabled(isPingingAll)
                        }
                        .padding(.horizontal, 4)

                        // 预设分组展示
                        let groups = Dictionary(grouping: NodePresetManager.defaultNodes, by: { $0.group })
                        ForEach(groups.keys.sorted(), id: \.self) { groupName in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(groupName)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.leading, 4)

                                ForEach(groups[groupName] ?? []) { node in
                                    nodeRow(node)
                                }
                            }
                        }

                        // 自定义节点分组
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("自定义节点")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.leading, 4)

                                Spacer()

                                Button {
                                    showAddSheet = true
                                } label: {
                                    Label("添加", systemImage: "plus.circle.fill")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(LiquidTheme.flamePrimary)
                                }
                            }

                            if customNodes.isEmpty {
                                LiquidGlassCard {
                                    HStack {
                                        Spacer()
                                        Text("暂无自定义节点，点击右上角添加")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.4))
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                }
                            } else {
                                ForEach(customNodes) { node in
                                    nodeRow(node)
                                }
                            }
                        }
                    }
                    .padding(18)
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
            HStack(spacing: 12) {
                Image(systemName: node.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(currentNode.id == node.id ? LiquidTheme.cyanPrimary : .white.opacity(0.6))
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(node.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text(node.urlString)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                        .lineLimit(1)
                }

                Spacer()

                if let ping = pingResults[node.id] {
                    Text("\(ping) ms")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(ping < 80 ? LiquidTheme.emerald : (ping < 200 ? LiquidTheme.flameSecondary : Color.red.opacity(0.8)))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.black.opacity(0.25)))
                }

                if currentNode.id == node.id {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(LiquidTheme.cyanPrimary)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .liquidGlass(
                cornerRadius: 14,
                innerTint: currentNode.id == node.id ? LiquidTheme.cyanPrimary.opacity(0.12) : Color.white.opacity(0.03)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var addNodeSheet: some View {
        NavigationStack {
            ZStack {
                LiquidMeshBackground()

                VStack(alignment: .leading, spacing: 18) {
                    LiquidGlassCard {
                        VStack(spacing: 12) {
                            TextField("节点名称 (如: 私有 CDN 镜像)", text: $newName)
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
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.9))
                            .padding(.horizontal, 4)
                    }

                    LiquidGlassButton(
                        title: isCheckingUrl ? "连通性检测中..." : "保存节点",
                        icon: "checkmark",
                        style: .burning
                    ) {
                        saveCustomNode()
                    }
                    .disabled(isCheckingUrl || newName.isEmpty || newUrl.isEmpty)

                    Spacer()
                }
                .padding(18)
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
