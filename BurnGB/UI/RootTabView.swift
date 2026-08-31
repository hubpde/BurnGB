//
//  RootTabView.swift
//  BurnGB
//
//  iOS 26 自适应 Tab 导航：iPhone 使用底部栏，iPad 可切换为侧边栏。
//

import SwiftUI

/// 顶层导航标签。
enum AppTab: Hashable {
    case dashboard
    case nodes
    case diagnostics
    case settings
}

/// 应用根导航容器。
struct RootTabView: View {
    @State private var selection: AppTab = .dashboard

    var body: some View {
        TabView(selection: $selection) {
            Tab("概览", systemImage: "gauge.with.dots.needle.bottom.50percent", value: .dashboard) {
                NavigationStack {
                    DashboardView()
                }
            }

            Tab("节点", systemImage: "network", value: .nodes) {
                NavigationStack {
                    NodeListView()
                }
            }

            Tab("诊断", systemImage: "waveform.path.ecg", value: .diagnostics) {
                NavigationStack {
                    IPDiagnosticsView()
                }
            }

            Tab("设置", systemImage: "gearshape", value: .settings) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        // iOS 26 官方自适应样式：iPhone 是 Tab Bar，iPad 可展开为 Sidebar。
        .tabViewStyle(.sidebarAdaptable)
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}
