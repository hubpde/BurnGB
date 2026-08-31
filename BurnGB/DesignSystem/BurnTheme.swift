//
//  BurnTheme.swift
//  BurnGB
//
//  面向 iOS 26 的系统主题与 Liquid Glass 组件。
//

import SwiftUI

/// 应用的语义强调色。
/// 颜色只用于表达状态，不把整个界面染成高饱和背景。
enum BurnTheme {
    static let accent = Color.orange
    static let speed = Color.blue
    static let success = Color.green
    static let warning = Color.yellow
    static let destructive = Color.red
}

/// iOS 26 Liquid Glass 卡片。
/// 玻璃效果只放在少量重要表面，避免嵌套材质和全屏模糊。
struct GlassCard<Content: View>: View {
    private let tint: Color?
    private let content: () -> Content

    init(tint: Color? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.tint = tint
        self.content = content
    }

    @ViewBuilder
    var body: some View {
        if let tint {
            content()
                .padding()
                .glassEffect(
                    .regular.tint(tint),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
        } else {
            content()
                .padding()
                .glassEffect(
                    .regular,
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
        }
    }
}

/// 将相邻的玻璃控件放入同一个容器，让系统协调折射和形状过渡。
struct GlassControlGroup<Content: View>: View {
    private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            content()
        }
    }
}

/// 使用 iOS 26 官方玻璃按钮样式的统一按钮。
struct NativeGlassButton: View {
    let title: LocalizedStringKey
    let systemImage: String?
    let prominent: Bool
    let action: () -> Void

    init(
        _ title: LocalizedStringKey,
        systemImage: String? = nil,
        prominent: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.prominent = prominent
        self.action = action
    }

    @ViewBuilder
    var body: some View {
        if prominent {
            button
                .buttonStyle(.glassProminent)
                .controlSize(.large)
        } else {
            button
                .buttonStyle(.glass)
                .controlSize(.large)
        }
    }

    @ViewBuilder
    private var button: some View {
        Button(action: action) {
            if let systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
        }
    }
}

/// 统一的数值文本样式，使用 monospacedDigit 防止数字变化时布局跳动。
struct MetricValueStyle: ViewModifier {
    var color: Color = .primary

    func body(content: Content) -> some View {
        content
            .font(.title2.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(color)
            .contentTransition(.numericText())
    }
}

extension View {
    func metricValueStyle(color: Color = .primary) -> some View {
        modifier(MetricValueStyle(color: color))
    }
}
