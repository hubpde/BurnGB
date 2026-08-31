//
//  BurnGBApp.swift
//  BurnGB
//
//  iOS 26 原生应用入口。
//

import SwiftUI

/// BurnGB 原生 SwiftUI App。
@main
@MainActor
struct BurnGBApp: App {
    /// UIKit 生命周期桥接器，负责后台任务注册。
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    /// Observation 模型，作为整个界面的环境依赖。
    @State private var model = AppModel()
    /// 当前场景状态。
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(model)
                .task {
                    model.installSystemHandlers(on: appDelegate)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    model.scenePhaseChanged(newPhase)
                }
        }
    }
}
