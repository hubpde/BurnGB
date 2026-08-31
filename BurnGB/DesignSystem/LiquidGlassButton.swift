//
//  LiquidGlassButton.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import SwiftUI

public enum LiquidButtonStyle {
    case burning
    case speedCyan
    case frostedGlass
    case danger
}

public struct LiquidGlassButton: View {
    public var title: String
    public var icon: String?
    public var style: LiquidButtonStyle
    public var isFullWidth: Bool
    public var isPulseActive: Bool
    public var action: () -> Void

    @State private var isPressed = false
    @State private var pulseScale: CGFloat = 1.0

    public init(
        title: String,
        icon: String? = nil,
        style: LiquidButtonStyle = .burning,
        isFullWidth: Bool = true,
        isPulseActive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isFullWidth = isFullWidth
        self.isPulseActive = isPulseActive
        self.action = action
    }

    public var body: some View {
        Button(action: {
            HapticManager.impact(.medium)
            action()
        }) {
            HStack(spacing: 10) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(backgroundView)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.8),
                                Color.white.opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            )
            .shadow(color: shadowColor, radius: 14, x: 0, y: 8)
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        ._onButtonGesture { pressing in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.65)) {
                isPressed = pressing
            }
        } perform: {}
    }

    @ViewBuilder
    private var backgroundView: some View {
        ZStack {
            switch style {
            case .burning:
                LiquidTheme.burningGradient
                RadialGradient(
                    colors: [Color.white.opacity(0.35), Color.clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 50
                )
            case .speedCyan:
                LiquidTheme.speedGradient
                RadialGradient(
                    colors: [Color.white.opacity(0.35), Color.clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 50
                )
            case .frostedGlass:
                Rectangle().fill(.ultraThinMaterial)
                Color.white.opacity(0.08)
            case .danger:
                LinearGradient(
                    colors: [Color.red.opacity(0.85), Color.orange.opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
    }

    private var shadowColor: Color {
        switch style {
        case .burning:
            return LiquidTheme.flamePrimary.opacity(0.45)
        case .speedCyan:
            return LiquidTheme.cyanPrimary.opacity(0.45)
        case .frostedGlass:
            return Color.black.opacity(0.3)
        case .danger:
            return Color.red.opacity(0.4)
        }
    }
}
