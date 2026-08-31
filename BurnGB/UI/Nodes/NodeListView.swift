//
//  NodeListView.swift
//  BurnGB
//
//  节点管理与并发延时探测。
//

import SwiftUI
import BurnGBCore

/// 节点管理页，使用系统 List、搜索和编辑 sheet。
struct NodeListView: View {
    @Environment(AppModel.self) private var model
    @State private var searchText = ""
    @State private var showsEditor = false

    private var filteredNodes: [BurnNode] {
        guard !searchText.isEmpty else { return model.nodes }
        return model.nodes.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.urlString.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groups: [String: [BurnNode]] {
        Dictionary(grouping: filteredNodes, by: \.group)
    }

    var body: some View {
        List {
            Section {
                Button {
                    model.probeAllNodes()
                } label: {
                    HStack {
                        Label("测量所有节点延时", systemImage: "waveform.path.ecg")
                        Spacer()
                        if model.isProbingNodes {
                            ProgressView()
                        }
                    }
                }
                .disabled(model.isProbingNodes)
            }

            ForEach(groups.keys.sorted(), id: \.self) { group in
                Section(group) {
                    ForEach(groups[group] ?? []) { node in
                        nodeRow(node)
                    }
                    .onDelete { offsets in
                        let customNodes = (groups[group] ?? []).filter(\.isCustom)
                        for index in offsets where index < customNodes.count {
                            model.removeNode(customNodes[index])
                        }
                    }
                }
            }
        }
        .navigationTitle("节点")
        .searchable(text: $searchText, prompt: "搜索节点或地址")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showsEditor = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("添加自定义节点")
            }
        }
        .sheet(isPresented: $showsEditor) {
            NodeEditorSheet()
        }
    }

    @ViewBuilder
    private func nodeRow(_ node: BurnNode) -> some View {
        HStack(spacing: 12) {
            Image(systemName: node.symbolName)
                .foregroundStyle(model.selectedNode.id == node.id ? .orange : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(node.name)
                        .font(.body.weight(.medium))
                    if model.selectedNode.id == node.id {
                        Text("当前")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.orange)
                    }
                }
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
        .contentShape(Rectangle())
        .onTapGesture {
            model.selectNode(node)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(node.name)
        .accessibilityValue(model.selectedNode.id == node.id ? "当前节点" : node.urlString)
    }
}

/// 新增自定义 HTTPS 节点的系统表单。
struct NodeEditorSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var url = ""
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("节点信息") {
                    TextField("名称", text: $name)
                    TextField("HTTPS 下载地址", text: $url)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }

                Section {
                    Text("请只添加自己拥有或明确获授权的测速端点。节点产生的流量费用由使用者承担。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let validationMessage {
                    Section {
                        Text(validationMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button("保存节点") {
                        if let error = model.addNode(name: name, urlString: url) {
                            validationMessage = error
                        } else {
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || url.isEmpty)
                }
            }
            .navigationTitle("添加节点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
