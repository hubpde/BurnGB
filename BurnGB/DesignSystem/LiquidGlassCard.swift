//
//  LiquidGlassCard.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import SwiftUI

public struct LiquidGlassModifier: ViewModifier {
    public var cornerRadius: CGFloat
    public var innerTint: Color
    public var glowColor: Color?
    public var elevation: CGFloat

    public init(
        cornerRadius: CGFloat = 24,
        innerTint: Color = Color.white.opacity(0.04),
        glowColor: Color? = nil,
        elevation: CGFloat = 8
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
                    // Ultra thin frosted base
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)

                    // Inner color tint
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(innerTint)

                    // Top specular rim reflection sheen
                    VStack {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.2),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                        Spacer()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.55), location: 0.0),
                                .init(color: Color.white.opacity(0.15), location: 0.35),
                                .init(color: Color.black.opacity(0.2), location: 0.8),
                                .init(color: Color.white.opacity(0.1), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
            .shadow(
                color: glowColor?.opacity(0.35) ?? Color.black.opacity(0.25),
                radius: elevation * 1.5,
                x: 0,
                y: elevation
            )
    }
}

public extension View {
    func liquidGlass(
        cornerRadius: CGFloat = 24,
        innerTint: Color = Color.white.opacity(0.04),
        glowColor: Color? = nil,
        elevation: CGFloat = 8
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

public struct LiquidGlassCard<Content: View>: View {
    public var cornerRadius: CGFloat
    public var innerTint: Color
    public var glowColor: Color?
    public var padding: CGFloat
    @ViewBuilder public var content: () -> Content

    public init(
        cornerRadius: CGFloat = 24,
        innerTint: Color = Color.white.opacity(0.04),
        glowColor: Color? = nil,
        padding: CGFloat = 18,
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
