//
//  LiquidGlassButton.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import SwiftUI

/// 按钮样式类型
public enum LiquidButtonStyle {
    /// 核心点火橙色
    case burning
    /// 科技测速青色
    case speedCyan
    /// 磨砂极简玻璃
    case frostedGlass
    /// 危险/停止红色
    case danger
}

/// 极简高质感液态玻璃交互按钮组件
public struct LiquidGlassButton: View {
    public var title: String
    public var icon: String?
    public var style: LiquidButtonStyle
    public var isFullWidth: Bool
    public var action: () -> Void

    @State private var isPressed = false

    public init(
        title: String,
        icon: String? = nil,
        style: LiquidButtonStyle = .burning,
        isFullWidth: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isFullWidth = isFullWidth
        self.action = action
    }

    public var body: some View {
        Button(action: {
            HapticManager.impact(.medium)
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.vertical, 14)
            .padding(.horizontal, 22)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(backgroundView)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
            .shadow(color: shadowColor, radius: 10, x: 0, y: 5)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        ._onButtonGesture { pressing in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        } perform: {}
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .burning:
            LiquidTheme.burningGradient
        case .speedCyan:
            LiquidTheme.speedGradient
        case .frostedGlass:
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Color.white.opacity(0.06)
            }
        case .danger:
            LinearGradient(
                colors: [Color(red: 0.95, green: 0.25, blue: 0.25), Color(red: 0.85, green: 0.15, blue: 0.15)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    private var shadowColor: Color {
        switch style {
        case .burning:
            return LiquidTheme.flamePrimary.opacity(0.3)
        case .speedCyan:
            return LiquidTheme.cyanPrimary.opacity(0.3)
        case .frostedGlass:
            return Color.black.opacity(0.2)
        case .danger:
            return Color.red.opacity(0.3)
        }
    }
}
