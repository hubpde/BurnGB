//
//  LiquidGlassCard.swift
//  BurnGB
//
//  Created for BurnGB - iOS Native Edition.
//

import SwiftUI

/// 官方原生卡片容器修饰器
/// 遵循 iOS 官方 Human Interface Guidelines，使用系统次级背景色与标准连续圆角
public struct NativeCardModifier: ViewModifier {
    public var cornerRadius: CGFloat

    public init(cornerRadius: CGFloat = 12) {
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        content
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

public extension View {
    /// 快捷应用 iOS 原生卡片容器质感
    func nativeCard(cornerRadius: CGFloat = 12) -> some View {
        self.modifier(NativeCardModifier(cornerRadius: cornerRadius))
    }

    /// 兼容已有调用的别名
    func liquidGlass(cornerRadius: CGFloat = 12, innerTint: Color = .clear, glowColor: Color? = nil, elevation: CGFloat = 0) -> some View {
        self.modifier(NativeCardModifier(cornerRadius: cornerRadius))
    }
}

/// 官方原生卡片容器组件
public struct LiquidGlassCard<Content: View>: View {
    public var cornerRadius: CGFloat
    public var padding: CGFloat
    @ViewBuilder public var content: () -> Content

    public init(
        cornerRadius: CGFloat = 12,
        innerTint: Color = .clear,
        glowColor: Color? = nil,
        padding: CGFloat = 14,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(padding)
        .nativeCard(cornerRadius: cornerRadius)
    }
}
