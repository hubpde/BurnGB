//
//  NodePickerSheetView.swift
//  BurnGB
//
//  主仪表盘弹出的轻量节点选择器。
//

import SwiftUI
import BurnGBCore

/// 只负责选择，不承载节点编辑逻辑。
struct NodePickerSheetView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredNodes: [BurnNode] {
        guard !searchText.isEmpty else { return model.nodes }
        return model.nodes.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.urlString.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedNodes.keys.sorted(), id: \.self) { group in
                    Section(group) {
                        ForEach(groupedNodes[group] ?? []) { node in
                            Button {
                                model.selectNode(node)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: node.symbolName)
                                        .foregroundStyle(model.selectedNode.id == node.id ? Color.orange : Color.secondary)
                                        .frame(width: 24)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(node.name)
                                            .foregroundStyle(.primary)
                                        Text(node.urlString)
                                            .font(.caption2.monospaced())
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    if model.selectedNode.id == node.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("选择节点")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "搜索节点")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private var groupedNodes: [String: [BurnNode]] {
        Dictionary(grouping: filteredNodes, by: \.group)
    }
}
