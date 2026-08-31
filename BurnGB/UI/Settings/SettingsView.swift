//
//  SettingsView.swift
//  BurnGB
//
//  应用偏好设置，使用系统 Form 与语义控件。
//

import SwiftUI
import UIKit
import ActivityKit

/// BurnGB 设置页。
struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var showsAbout = false

    private var activitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    var body: some View {
        Form {
            Section {
                Toggle(
                    "请求后台持续处理",
                    isOn: Binding(
                        get: { model.requestsBackgroundContinuation },
                        set: { model.requestsBackgroundContinuation = $0 }
                    )
                )
                .tint(.orange)

                Toggle(
                    "实时活动与灵动岛",
                    isOn: Binding(
                        get: { model.liveActivityEnabled },
                        set: { model.liveActivityEnabled = $0 }
                    )
                )
                .tint(.orange)
            } header: {
                Text("运行偏好")
            } footer: {
                Text("后台任务和实时活动均由 iOS 系统调度。它们不会授予永久后台执行权，也不会保证固定的更新频率。")
            }

            Section("系统能力") {
                LabeledContent("最低系统版本", value: "iOS 26")
                LabeledContent("实时活动权限", value: activitiesEnabled ? "已允许" : "未允许")
                LabeledContent("频繁更新资格", value: frequentPushesEnabled ? "允许" : "受系统限制")
                LabeledContent("后台状态", value: backgroundStateText)
            }

            Section("统计口径") {
                Text("BurnGB 统计的是应用层收到并计入账本的字节数。协议开销、缓存、压缩和运营商计费规则可能使最终计费流量不同。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("关于 BurnGB") {
                    showsAbout = true
                }
                Button("Apple 后台能力说明") {
                    if let url = URL(string: "https://developer.apple.com/documentation/backgroundtasks/performing-long-running-tasks-on-ios-and-ipados") {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
        .navigationTitle("设置")
        .sheet(isPresented: $showsAbout) {
            AboutView()
        }
    }

    private var frequentPushesEnabled: Bool {
        ActivityAuthorizationInfo().frequentPushesEnabled
    }

    private var backgroundStateText: String {
        switch model.snapshot.backgroundState {
        case .foreground: "前台"
        case .submitting: "提交中"
        case .running: "系统执行中"
        case .waitingForSystem: "等待系统"
        case .unavailable: "不可用"
        case .expired: "已过期"
        case .interrupted: "已中断"
        }
    }
}
