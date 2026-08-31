//
//  LiquidGlassCard.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import SwiftUI

/// iOS 26 极简液态玻璃卡片修饰器
/// 融合超薄材质、单像素微光描边与柔和阴影，呈现苹果顶级原生工业设计质感
public struct LiquidGlassModifier: ViewModifier {
    /// 卡片连续圆角半径
    public var cornerRadius: CGFloat
    /// 内部微光填充色
    public var innerTint: Color
    /// 外发光辅助色
    public var glowColor: Color?
    /// 投影高度
    public var elevation: CGFloat

    public init(
        cornerRadius: CGFloat = 20,
        innerTint: Color = Color.white.opacity(0.03),
        glowColor: Color? = nil,
        elevation: CGFloat = 6
    ) {
        self.cornerRadius = cornerRadius
        self.innerTint = innerTint
        self.glowColor = glowColor
        self.elevation = elevation
    }

    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // 超薄磨砂材质底板
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)

                    // 内部极简微光
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(innerTint)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                // 0.6pt 超细微光折射外边框
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.35), location: 0.0),
                                .init(color: Color.white.opacity(0.08), location: 0.4),
                                .init(color: Color.white.opacity(0.02), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.6
                    )
            )
            .shadow(
                color: glowColor?.opacity(0.2) ?? Color.black.opacity(0.18),
                radius: elevation * 1.5,
                x: 0,
                y: elevation
            )
    }
}

public extension View {
    /// 快捷附加液态玻璃卡片质感
    func liquidGlass(
        cornerRadius: CGFloat = 20,
        innerTint: Color = Color.white.opacity(0.03),
        glowColor: Color? = nil,
        elevation: CGFloat = 6
    ) -> some View {
        self.modifier(
            LiquidGlassModifier(
                cornerRadius: cornerRadius,
                innerTint: innerTint,
                glowColor: glowColor,
                elevation: elevation
            )
        )
    }
}

/// 极简液态玻璃卡片容器组件
public struct LiquidGlassCard<Content: View>: View {
    public var cornerRadius: CGFloat
    public var innerTint: Color
    public var glowColor: Color?
    public var padding: CGFloat
    @ViewBuilder public var content: () -> Content

    public init(
        cornerRadius: CGFloat = 20,
        innerTint: Color = Color.white.opacity(0.03),
        glowColor: Color? = nil,
        padding: CGFloat = 16,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.innerTint = innerTint
        self.glowColor = glowColor
        self.padding = padding
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(padding)
        .liquidGlass(
            cornerRadius: cornerRadius,
            innerTint: innerTint,
            glowColor: glowColor
        )
    }
}
