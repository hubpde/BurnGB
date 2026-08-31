//
//  LiquidGlassButton.swift
//  BurnGB
//
//  Created for BurnGB - iOS Native Edition.
//

import SwiftUI

/// 原生按钮风格类型
public enum LiquidButtonStyle {
    /// 核心能量橙色（拉取点火）
    case burning
    /// 科技测速蓝色
    case speedCyan
    /// 次要灰色背景
    case frostedGlass
    /// 危险/停止红色
    case danger
}

/// 官方原生高质感按钮组件
public struct LiquidGlassButton: View {
    public var title: String
    public var icon: String?
    public var style: LiquidButtonStyle
    public var isFullWidth: Bool
    public var action: () -> Void

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
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(foregroundColor)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color {
        switch style {
        case .burning:
            return Color.orange
        case .speedCyan:
            return Color.blue
        case .frostedGlass:
            return Color(uiColor: .tertiarySystemFill)
        case .danger:
            return Color.red
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .burning, .speedCyan, .danger:
            return .white
        case .frostedGlass:
            return .primary
        }
    }
}
