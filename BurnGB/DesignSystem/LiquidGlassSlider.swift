//
//  LiquidGlassSlider.swift
//  BurnGB
//
//  Created for BurnGB - iOS Native Edition.
//

import SwiftUI

/// 官方原生滑块调节组件
public struct LiquidGlassSlider: View {
    @Binding public var value: Double
    public var range: ClosedRange<Double>
    public var step: Double
    public var label: String
    public var displayValue: String
    public var tintColor: Color

    public init(
        value: Binding<Double>,
        in range: ClosedRange<Double> = 1...64,
        step: Double = 1,
        label: String = "并发线程数",
        displayValue: String = "",
        tintColor: Color = Color.orange
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.label = label
        self.displayValue = displayValue
        self.tintColor = tintColor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                Text(displayValue.isEmpty ? "\(Int(value)) 线程" : displayValue)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(tintColor)
            }

            Slider(value: $value, in: range, step: step)
                .tint(tintColor)
                .onChange(of: value) { _ in
                    HapticManager.selection()
                }
        }
    }
}
