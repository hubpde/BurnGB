//
//  LiquidGlassSlider.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import SwiftUI

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
        label: String = "线程并发数",
        displayValue: String = "",
        tintColor: Color = LiquidTheme.cyanPrimary
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.label = label
        self.displayValue = displayValue
        self.tintColor = tintColor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text(displayValue.isEmpty ? "\(Int(value))" : displayValue)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(tintColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(tintColor.opacity(0.15))
                            .overlay(
                                Capsule().stroke(tintColor.opacity(0.3), lineWidth: 0.8)
                            )
                    )
            }

            Slider(value: $value, in: range, step: step)
                .tint(tintColor)
                .onChange(of: value) { _ in
                    HapticManager.selection()
                }
        }
    }
}
