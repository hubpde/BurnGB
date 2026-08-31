//
//  RunControlsView.swift
//  BurnGB
//
//  主屏开始、暂停、恢复、终止控制。
//

import SwiftUI

/// 使用系统玻璃按钮样式的任务控制区。
struct RunControlsView: View {
    @Environment(AppModel.self) private var model
    @State private var showsStopConfirmation = false

    var body: some View {
        GlassControlGroup {
            if model.isRunning {
                HStack(spacing: 12) {
                    Button {
                        if model.isPaused {
                            model.resume()
                        } else {
                            model.pause()
                        }
                    } label: {
                        Label(
                            model.isPaused ? "继续" : "暂停",
                            systemImage: model.isPaused ? "play.fill" : "pause.fill"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                    .accessibilityHint(model.isPaused ? "继续网络流量消耗" : "暂时暂停网络流量消耗")

                    Button(role: .destructive) {
                        showsStopConfirmation = true
                    } label: {
                        Label("终止", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                    .accessibilityHint("终止当前任务并停止所有网络连接")
                }
            } else {
                Button {
                    model.start()
                } label: {
                    Label("开始消耗流量", systemImage: "arrow.down.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .tint(.orange)
                .disabled(model.isPerformingAction)
                .accessibilityHint("前台开始网络流量消耗，并请求 iOS 26 后台持续处理任务")
            }
        }
        .confirmationDialog(
            "确定终止当前任务？",
            isPresented: $showsStopConfirmation,
            titleVisibility: .visible
        ) {
            Button("终止任务", role: .destructive) {
                model.stop()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("终止后所有下载连接会被取消，当前统计会保留。")
        }
    }
}
