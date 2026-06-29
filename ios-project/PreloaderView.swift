//
//  PreloaderView.swift
//  ios-project

import SwiftUI

// MARK: - Theme

private enum T {
    static let bg       = Color(red: 0.067, green: 0.067, blue: 0.067)
    static let accent   = Color(red: 0.545, green: 0.361, blue: 0.965)
    static let highlight = Color(red: 0.655, green: 0.545, blue: 0.98)
    static let secondary = Color(red: 0.69,  green: 0.69,  blue: 0.69)
}

// MARK: - Layered Orb Background

private struct PreloaderBackground: View {
    @State private var rotate: Bool = false

    var body: some View {
        ZStack {
            // Base
            T.bg.ignoresSafeArea()

            // Top-left deep purple orb
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.42, green: 0.18, blue: 0.82).opacity(0.55),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 220
                    )
                )
                .frame(width: 420, height: 380)
                .blur(radius: 60)
                .offset(x: -80, y: -260)
                .rotationEffect(.degrees(rotate ? 12 : -12))
                .animation(
                    .easeInOut(duration: 8).repeatForever(autoreverses: true),
                    value: rotate
                )

            // Bottom-right violet orb
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.55, green: 0.35, blue: 0.98).opacity(0.40),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 360, height: 320)
                .blur(radius: 55)
                .offset(x: 100, y: 320)
                .rotationEffect(.degrees(rotate ? -10 : 10))
                .animation(
                    .easeInOut(duration: 10).repeatForever(autoreverses: true),
                    value: rotate
                )

            // Subtle center glow that syncs with title
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            T.accent.opacity(0.12),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 160
                    )
                )
                .frame(width: 300, height: 180)
                .blur(radius: 40)
                .offset(y: -60)
        }
        .onAppear { rotate = true }
    }
}

// MARK: - Tap Ripple Loading Animation

private struct TapRippleLoader: View {
    private let ringCount = 4

    @State private var animating = false
    @State private var fingerScale: CGFloat = 1.0
    @State private var fingerOpacity: Double = 0.9

    var body: some View {
        ZStack {
            ForEach(0..<ringCount, id: \.self) { i in
                RippleRing(
                    color: T.accent,
                    delay: Double(i) * 0.38,
                    animating: animating
                )
            }

            Image(systemName: "hand.tap.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(T.accent)
                .scaleEffect(fingerScale)
                .opacity(fingerOpacity)
                .shadow(color: T.accent.opacity(0.6), radius: 8)
        }
        .frame(width: 120, height: 120)
        .onAppear {
            animating = true
            pulseFingerLoop()
        }
    }

    private func pulseFingerLoop() {
        withAnimation(.easeIn(duration: 0.08)) {
            fingerScale   = 0.78
            fingerOpacity = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.5)) {
                fingerScale   = 1.08
                fingerOpacity = 0.9
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            withAnimation(.easeOut(duration: 0.2)) {
                fingerScale   = 1.0
                fingerOpacity = 0.85
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.52) {
            pulseFingerLoop()
        }
    }
}

private struct RippleRing: View {
    let color: Color
    let delay: Double
    let animating: Bool

    @State private var scale: CGFloat  = 0.1
    @State private var opacity: Double = 0.0
    private let duration = 1.52

    var body: some View {
        Circle()
            .strokeBorder(color, lineWidth: 2)
            .frame(width: 80, height: 80)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                guard animating else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    startRipple()
                }
            }
    }

    private func startRipple() {
        scale   = 0.1
        opacity = 0.0
        withAnimation(.easeOut(duration: 0.12)) { opacity = 0.85 }
        withAnimation(.easeOut(duration: duration)) { scale = 1.85 }
        withAnimation(.easeIn(duration: duration * 0.75).delay(duration * 0.25)) { opacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { startRipple() }
    }
}

// MARK: - Load Stage Label

private struct LoadLabel: View {
    let progress: Double

    private var label: String {
        switch progress {
        case ..<0.25: return "INITIALIZING"
        case ..<0.55: return "LOADING ASSETS"
        case ..<0.80: return "BUILDING ARENA"
        case ..<1.00: return "ALMOST READY"
        default:       return "LET'S GO"
        }
    }

    var body: some View {
        Text(label)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundColor(T.highlight.opacity(0.7))
            .tracking(3)
    }
}

// MARK: - PreloaderView

struct PreloaderView: View {
    let onComplete: () -> Void

    @State private var logoScale: CGFloat      = 0.6
    @State private var logoOpacity: Double     = 0
    @State private var subtitleOpacity: Double = 0
    @State private var pulseScale: CGFloat     = 1.0
    @State private var pulseOpacity: Double    = 0.12
    @State private var loaderOpacity: Double   = 0
    @State private var loadProgress: Double    = 0.0

    var body: some View {
        ZStack {
            PreloaderBackground()

            // Soft accent pulse behind title
            Circle()
                .fill(
                    RadialGradient(
                        colors: [T.accent.opacity(0.22), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 320, height: 320)
                .scaleEffect(pulseScale)
                .opacity(pulseOpacity)
                .animation(
                    .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                    value: pulseScale
                )

            VStack(spacing: 18) {
                Text("TAP ARENA")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(6)
                    .shadow(color: T.accent.opacity(0.55), radius: 20)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                Text("READY YOUR FINGERS")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(T.secondary)
                    .tracking(5)
                    .opacity(subtitleOpacity)

                VStack(spacing: 14) {
                    TapRippleLoader()
                    LoadLabel(progress: loadProgress)
                }
                .opacity(loaderOpacity)
                .padding(.top, 12)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) {
                logoScale   = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale   = 1.15
                pulseOpacity = 0.22
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.55)) {
                subtitleOpacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.7)) {
                loaderOpacity = 1.0
            }
            simulateLoad()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                onComplete()
            }
        }
    }

    private func simulateLoad() {
        let steps: [(Double, Double)] = [
            (0.40, 0.18), (0.70, 0.42), (1.00, 0.61),
            (1.30, 0.78), (1.65, 0.92), (2.00, 1.00)
        ]
        for (delay, target) in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.25)) { loadProgress = target }
            }
        }
    }
}

#Preview {
    PreloaderView(onComplete: {})
}
