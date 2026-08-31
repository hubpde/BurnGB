//
//  LiquidGradients.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import SwiftUI

/// 极简高质感配色与渐变定义（Apple Pro 质感）
public enum LiquidTheme {
    // MARK: - 主色调定义
    /// 核心能量橙红色（点火状态主色）
    public static let flamePrimary = Color(red: 1.00, green: 0.35, blue: 0.12)
    /// 辅助暖金橙色
    public static let flameSecondary = Color(red: 1.00, green: 0.62, blue: 0.15)
    /// 速率电光青（科技测速主色）
    public static let cyanPrimary = Color(red: 0.15, green: 0.78, blue: 0.95)
    /// 稳态翡翠绿（就绪/成功状态色）
    public static let emerald = Color(red: 0.20, green: 0.85, blue: 0.55)

    // MARK: - 质感渐变定义
    /// 点火拉取渐变色
    public static let burningGradient = LinearGradient(
        colors: [flamePrimary, flameSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// 速率指示渐变色
    public static let speedGradient = LinearGradient(
        colors: [cyanPrimary, Color(red: 0.25, green: 0.55, blue: 1.0)],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// 玻璃边缘微光反射描边渐变
    public static let glassRimHighlight = LinearGradient(
        colors: [
            Color.white.opacity(0.35),
            Color.white.opacity(0.08),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// 极简高级液态磨砂背景组件
/// 采用深邃黑曜石底色搭配极度克制的微环境漫反射，保证视觉极简、纯净、无冗余杂色干扰
public struct LiquidMeshBackground: View {
    @State private var animate = false

    public init() {}

    public var body: some View {
        ZStack {
            // 深邃黑曜石底色
            Color(red: 0.05, green: 0.06, blue: 0.08)
                .ignoresSafeArea()

            // 极简微弱柔和环境光斑（超大羽化模糊，克制不喧宾夺主）
            GeometryReader { proxy in
                let size = proxy.size

                // 左上方微弱科技青晕
                Circle()
                    .fill(LiquidTheme.cyanPrimary.opacity(0.12))
                    .frame(width: size.width * 0.9, height: size.width * 0.9)
                    .blur(radius: 100)
                    .offset(x: animate ? -size.width * 0.1 : 0, y: -size.height * 0.1)

                // 右下方微弱能量橙晕
                Circle()
                    .fill(LiquidTheme.flamePrimary.opacity(0.10))
                    .frame(width: size.width * 0.9, height: size.width * 0.9)
                    .blur(radius: 110)
                    .offset(x: size.width * 0.2, y: animate ? size.height * 0.4 : size.height * 0.3)
            }
            .ignoresSafeArea()

            // 顶级磨砂材质层
            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.6))
                .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}
