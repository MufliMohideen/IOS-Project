//
//  PreloaderView.swift
//  ios-project

import SwiftUI

// MARK: - Tap Ripple Loading Animation

private struct TapRippleLoader: View {
    // Each ring has its own phase offset so they stagger naturally
    private let ringCount = 4
    private let ringColor = Color(red: 1, green: 0.3, blue: 0.3)

    @State private var animating = false
    @State private var fingerScale: CGFloat = 1.0
    @State private var fingerOpacity: Double = 0.9

    var body: some View {
        ZStack {
            // Ripple rings — each delayed by its index
            ForEach(0..<ringCount, id: \.self) { i in
                RippleRing(
                    color: ringColor,
                    delay: Double(i) * 0.38,
                    animating: animating
                )
            }

            // Tap finger icon at center
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(ringColor)
                .scaleEffect(fingerScale)
                .opacity(fingerOpacity)
                .shadow(color: ringColor.opacity(0.6), radius: 8)
        }
        .frame(width: 120, height: 120)
        .onAppear {
            animating = true
            // Finger pulses on each "tap" cycle (matches ripple period ~1.5s)
            withAnimation(
                .easeInOut(duration: 0.12)
                .repeatForever(autoreverses: false)
                .delay(0)
            ) { }
            pulseFingerLoop()
        }
    }

    private func pulseFingerLoop() {
        // Quick compress → release → hold, repeat every 1.52s (matches ring period)
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

    // Each ring expands from near-zero to 1.8× over ~1.5s then resets
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
        // Reset to starting state without animation
        scale   = 0.1
        opacity = 0.0

        // Fade in quickly at small size
        withAnimation(.easeOut(duration: 0.12)) {
            opacity = 0.85
        }
        // Expand and fade out over full duration
        withAnimation(.easeOut(duration: duration)) {
            scale = 1.85
        }
        withAnimation(.easeIn(duration: duration * 0.75).delay(duration * 0.25)) {
            opacity = 0
        }
        // Loop
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            startRipple()
        }
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
            .foregroundColor(Color(red: 1, green: 0.4, blue: 0.4).opacity(0.65))
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
    @State private var pulseOpacity: Double    = 0.18
    @State private var loaderOpacity: Double   = 0
    @State private var loadProgress: Double    = 0.0

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.06, blue: 0.10),
                         Color(red: 0.04, green: 0.04, blue: 0.08)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Pulsing circle behind title
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.9, green: 0.2, blue: 0.2).opacity(0.35), Color.clear],
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
                // Title
                Text("TAP ARENA")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(6)
                    .shadow(color: Color(red: 1, green: 0.3, blue: 0.3).opacity(0.6), radius: 20)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                Text("READY YOUR FINGERS")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(5)
                    .opacity(subtitleOpacity)

                // Loading section
                VStack(spacing: 14) {
                    TapRippleLoader()

                    LoadLabel(progress: loadProgress)
                }
                .opacity(loaderOpacity)
                .padding(.top, 12)
            }
        }
        .onAppear {
            // Title entrance (original feel preserved)
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) {
                logoScale   = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale   = 1.15
                pulseOpacity = 0.28
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.55)) {
                subtitleOpacity = 1.0
            }

            // Loader fades in after title settles
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
            (0.40, 0.18),
            (0.70, 0.42),
            (1.00, 0.61),
            (1.30, 0.78),
            (1.65, 0.92),
            (2.00, 1.00)
        ]
        for (delay, target) in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.25)) {
                    loadProgress = target
                }
            }
        }
    }
}

#Preview {
    PreloaderView(onComplete: {})
}
