//
//  LiquidGaugeView.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import SwiftUI

public struct LiquidGaugeView: View {
    public var speedValue: String
    public var speedUnit: String
    public var bitrateText: String
    public var progress: Double // 0.0 to 1.0 (based on speed scale or quota)
    public var isRunning: Bool
    public var flameMode: Bool

    @State private var rotationAngle: Double = 0
    @State private var pulseWave: CGFloat = 1.0

    public init(
        speedValue: String,
        speedUnit: String,
        bitrateText: String,
        progress: Double = 0.0,
        isRunning: Bool = false,
        flameMode: Bool = true
    ) {
        self.speedValue = speedValue
        self.speedUnit = speedUnit
        self.bitrateText = bitrateText
        self.progress = min(max(progress, 0.0), 1.0)
        self.isRunning = isRunning
        self.flameMode = flameMode
    }

    public var body: some View {
        ZStack {
            // Background glow halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            (flameMode ? LiquidTheme.flamePrimary : LiquidTheme.cyanPrimary).opacity(isRunning ? 0.35 : 0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 130
                    )
                )
                .frame(width: 260, height: 260)
                .scaleEffect(isRunning ? pulseWave : 1.0)

            // Outer Track (Frosted glass circle)
            Circle()
                .stroke(
                    Color.white.opacity(0.08),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .frame(width: 220, height: 220)

            // Dynamic Progress Gauge Arc
            Circle()
                .trim(from: 0.0, to: isRunning ? max(progress, 0.06) : 0.0)
                .stroke(
                    AngularGradient(
                        colors: flameMode
                            ? [LiquidTheme.flameAccent, LiquidTheme.flamePrimary, LiquidTheme.flameSecondary, LiquidTheme.flameAccent]
                            : [LiquidTheme.cyanPrimary, LiquidTheme.cyanSecondary, LiquidTheme.violetPrimary, LiquidTheme.cyanPrimary],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.75), value: progress)
                .shadow(
                    color: (flameMode ? LiquidTheme.flamePrimary : LiquidTheme.cyanPrimary).opacity(isRunning ? 0.7 : 0.0),
                    radius: 12,
                    x: 0,
                    y: 0
                )

            // Center Info Glass Core
            VStack(spacing: 4) {
                if isRunning {
                    Image(systemName: flameMode ? "flame.fill" : "bolt.horizontal.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(
                            flameMode ? LiquidTheme.burningGradient : LiquidTheme.speedGradient
                        )
                        .scaleEffect(pulseWave)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseWave)
                } else {
                    Image(systemName: "powersleep")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }

                // Speed Big Number
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(speedValue)
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text(speedUnit)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(flameMode ? LiquidTheme.flameSecondary : LiquidTheme.cyanPrimary)
                }

                // Bitrate
                Text(bitrateText)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 2)
            }
            .padding(28)
            .liquidGlass(
                cornerRadius: 100,
                innerTint: Color.black.opacity(0.2),
                glowColor: isRunning ? (flameMode ? LiquidTheme.flamePrimary : LiquidTheme.cyanPrimary) : nil,
                elevation: 4
            )
        }
        .onAppear {
            if isRunning {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulseWave = 1.08
                }
            }
        }
        .onChange(of: isRunning) { running in
            if running {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulseWave = 1.08
                }
            } else {
                pulseWave = 1.0
            }
        }
    }
}
