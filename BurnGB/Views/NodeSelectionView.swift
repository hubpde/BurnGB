//
//  NodeSelectionView.swift
//  BurnGB
//
//  Created for BurnGB - iOS Native Edition.
//

import SwiftUI

/// 测速节点切换与延时探测视图（标准 iOS List 列表设计）
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
            List {
                // 顶部操作区
                Section {
                    Button {
                        pingAllNodes()
                    } label: {
                        HStack {
                            Label("测量全部节点延时", systemImage: "waveform.path.ecg")
                                .foregroundColor(.blue)
                            Spacer()
                            if isPingingAll {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isPingingAll)
                }

                // 预设分组展示
                let groups = Dictionary(grouping: NodePresetManager.defaultNodes, by: { $0.group })
                ForEach(groups.keys.sorted(), id: \.self) { groupName in
                    Section(header: Text(groupName)) {
                        ForEach(groups[groupName] ?? []) { node in
                            nodeRow(node)
                        }
                    }
                }

                // 自定义节点分组
                Section(header: Text("自定义节点")) {
                    ForEach(customNodes) { node in
                        nodeRow(node)
                    }
                    .onDelete(perform: deleteCustomNode)

                    Button {
                        showAddSheet = true
                    } label: {
                        Label("添加自定义节点", systemImage: "plus.circle")
                            .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle("选择测速节点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
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
                    .foregroundColor(currentNode.id == node.id ? .orange : .secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(node.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    Text(node.urlString)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if let ping = pingResults[node.id] {
                    Text("\(ping) ms")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(ping < 80 ? .green : (ping < 200 ? .orange : .red))
                }

                if currentNode.id == node.id {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.orange)
                }
            }
        }
    }

    private var addNodeSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("节点信息")) {
                    TextField("节点名称 (如: 私有 CDN 镜像)", text: $newName)
                    TextField("URL 下载链接 (支持 HTTP/HTTPS)", text: $newUrl)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                }

                if let error = urlError {
                    Section {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                    }
                }

                Section {
                    Button(isCheckingUrl ? "连通性检测中..." : "保存节点") {
                        saveCustomNode()
                    }
                    .disabled(isCheckingUrl || newName.isEmpty || newUrl.isEmpty)
                }
            }
            .navigationTitle("添加节点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showAddSheet = false }
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
                    iconName: "link",
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

    private func deleteCustomNode(at offsets: IndexSet) {
        customNodes.remove(atOffsets: offsets)
        saveCustomNodes()
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
