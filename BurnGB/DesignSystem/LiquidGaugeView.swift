//
//  LiquidGaugeView.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import SwiftUI

/// 极简高质感速率与能量仪表盘组件
/// 以大号清晰数字为主体，环形微光进度条配合柔和状态脉动，告别花哨杂色
public struct LiquidGaugeView: View {
    /// 速率数值文本（如 "124.5"）
    public var speedValue: String
    /// 速率单位文本（如 "MB/s"）
    public var speedUnit: String
    /// 比特带宽文本（如 "996.0 Mbps"）
    public var bitrateText: String
    /// 进度百分比（0.0 ~ 1.0）
    public var progress: Double
    /// 引擎是否处于活跃运行中
    public var isRunning: Bool

    @State private var pulseWave: CGFloat = 1.0

    public init(
        speedValue: String,
        speedUnit: String,
        bitrateText: String,
        progress: Double = 0.0,
        isRunning: Bool = false
    ) {
        self.speedValue = speedValue
        self.speedUnit = speedUnit
        self.bitrateText = bitrateText
        self.progress = min(max(progress, 0.0), 1.0)
        self.isRunning = isRunning
    }

    public var body: some View {
        ZStack {
            // 背景极简微弱柔光
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            (isRunning ? LiquidTheme.flamePrimary : LiquidTheme.cyanPrimary).opacity(isRunning ? 0.18 : 0.04),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 110
                    )
                )
                .frame(width: 230, height: 230)
                .scaleEffect(isRunning ? pulseWave : 1.0)

            // 外环底轨（极细磨砂圆环）
            Circle()
                .stroke(
                    Color.white.opacity(0.06),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 190, height: 190)

            // 动态进度环弧线
            Circle()
                .trim(from: 0.0, to: isRunning ? max(progress, 0.04) : 0.0)
                .stroke(
                    AngularGradient(
                        colors: [
                            LiquidTheme.flamePrimary,
                            LiquidTheme.flameSecondary,
                            LiquidTheme.flamePrimary
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 190, height: 190)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)

            // 中心核心速率展示区
            VStack(spacing: 2) {
                // 状态指示小图标
                Image(systemName: isRunning ? "flame.fill" : "bolt.horizontal.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(
                        isRunning ? LiquidTheme.burningGradient : LiquidTheme.speedGradient
                    )
                    .padding(.bottom, 2)

                // 核心大数字
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(speedValue)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(speedUnit)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(LiquidTheme.flameSecondary)
                }

                // 带宽文本
                Text(bitrateText)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.55))
            }
            .padding(24)
            .liquidGlass(
                cornerRadius: 90,
                innerTint: Color.black.opacity(0.25),
                elevation: 4
            )
        }
        .onAppear {
            if isRunning {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseWave = 1.05
                }
            }
        }
        .onChange(of: isRunning) { running in
            if running {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseWave = 1.05
                }
            } else {
                pulseWave = 1.0
            }
        }
    }
}
