//
//  LiquidGradients.swift
//  BurnGB
//
//  Created for BurnGB - iOS 26 Liquid Glass Edition.
//

import SwiftUI

public enum LiquidTheme {
    // Primary Vibrant Accents
    public static let flamePrimary = Color(red: 1.00, green: 0.36, blue: 0.15)    // #FF5C26
    public static let flameSecondary = Color(red: 1.00, green: 0.65, blue: 0.10)  // #FFA61A
    public static let flameAccent = Color(red: 1.00, green: 0.18, blue: 0.45)     // #FF2E73

    public static let cyanPrimary = Color(red: 0.05, green: 0.85, blue: 0.95)     // #0DD9F2
    public static let cyanSecondary = Color(red: 0.15, green: 0.55, blue: 1.00)   // #268CFF
    public static let violetPrimary = Color(red: 0.62, green: 0.28, blue: 1.00)   // #9E47FF

    public static let emerald = Color(red: 0.15, green: 0.88, blue: 0.55)         // #26E08C
    public static let glassDarkBase = Color(red: 0.06, green: 0.07, blue: 0.10)   // #0F121A

    // Gradients
    public static let burningGradient = LinearGradient(
        colors: [flameAccent, flamePrimary, flameSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let speedGradient = LinearGradient(
        colors: [cyanPrimary, cyanSecondary, violetPrimary],
        startPoint: .leading,
        endPoint: .trailing
    )

    public static let glassRimHighlight = LinearGradient(
        colors: [
            Color.white.opacity(0.65),
            Color.white.opacity(0.20),
            Color.white.opacity(0.05),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let glassDarkBorder = LinearGradient(
        colors: [
            Color.white.opacity(0.25),
            Color.white.opacity(0.05),
            Color.black.opacity(0.3)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

public struct LiquidMeshBackground: View {
    @State private var animate = false

    public init() {}

    public var body: some View {
        ZStack {
            // Deep base
            Color(red: 0.04, green: 0.05, blue: 0.08)
                .ignoresSafeArea()

            // Dynamic fluid ambient orbs
            GeometryReader { proxy in
                let size = proxy.size

                // Blob 1 - Top Left Cyan
                Circle()
                    .fill(LiquidTheme.cyanPrimary.opacity(0.35))
                    .frame(width: size.width * 0.85, height: size.width * 0.85)
                    .blur(radius: 80)
                    .offset(
                        x: animate ? -size.width * 0.2 : size.width * 0.05,
                        y: animate ? -size.height * 0.15 : -size.height * 0.05
                    )

                // Blob 2 - Center Right Flame/Violet
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [LiquidTheme.flamePrimary.opacity(0.4), LiquidTheme.violetPrimary.opacity(0.3)],
                            center: .center,
                            startRadius: 20,
                            endRadius: size.width * 0.4
                        )
                    )
                    .frame(width: size.width * 0.9, height: size.width * 0.9)
                    .blur(radius: 90)
                    .offset(
                        x: animate ? size.width * 0.25 : size.width * 0.05,
                        y: animate ? size.height * 0.15 : size.height * 0.35
                    )

                // Blob 3 - Bottom Left Deep Indigo
                Circle()
                    .fill(LiquidTheme.violetPrimary.opacity(0.3))
                    .frame(width: size.width * 0.75, height: size.width * 0.75)
                    .blur(radius: 75)
                    .offset(
                        x: animate ? -size.width * 0.15 : size.width * 0.1,
                        y: animate ? size.height * 0.6 : size.height * 0.45
                    )
            }
            .ignoresSafeArea()

            // Subtle frosted overlay
            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.4))
                .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 7.0).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}
