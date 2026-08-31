//
//  BurnGBApp.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import SwiftUI

/// BurnGB 应用启动主入口
@main
struct BurnGBApp: App {
    var body: some Scene {
        WindowGroup {
            MainDashboardView()
                // 默认强制全局暗色系以完美呈现 Liquid Glass 磨砂折射质感
                .preferredColorScheme(.dark)
        }
    }
}
