//
//  LiquidGradients.swift
//  BurnGB
//
//  Created for BurnGB - iOS Native Edition.
//

import SwiftUI

/// 官方原生主题配色定义
public enum NativeTheme {
    /// 核心能量橙色（拉取与点火强调色）
    public static let primaryOrange = Color.orange

    /// 科技测速青蓝色
    public static let primaryBlue = Color.blue

    /// 状态绿色（就绪与正常）
    public static let successGreen = Color.green

    /// 状态红色（停止与异常）
    public static let dangerRed = Color.red
}

/// 纯原生系统背景组件（完美适配 iOS 原生深色/浅色模式）
public struct NativeBackground: View {
    public init() {}

    public var body: some View {
        Color(uiColor: .systemGroupedBackground)
            .ignoresSafeArea()
    }
}
