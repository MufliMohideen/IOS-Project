//
//  HomeView.swift
//  ios-project
//

import SwiftUI

// MARK: - Theme

private enum T {
    static let bg        = Color(red: 0.067, green: 0.067, blue: 0.067)
    static let surface   = Color(red: 0.11,  green: 0.11,  blue: 0.118)
    static let card      = Color(red: 0.173, green: 0.173, blue: 0.18)
    static let accent    = Color(red: 0.545, green: 0.361, blue: 0.965)
    static let highlight = Color(red: 0.655, green: 0.545, blue: 0.98)
    static let secondary = Color(red: 0.69,  green: 0.69,  blue: 0.69)
}

struct HomeView: View {
    @EnvironmentObject var scoreStore: ScoreStore

    var body: some View {
        NavigationStack {
            ZStack {
                HomeBackground()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        Text("TAP ARENA")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(5)
                            .shadow(color: T.accent.opacity(0.5), radius: 14)

                        Text("CHOOSE YOUR GAME")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(T.secondary)
                            .tracking(4)
                    }
                    .padding(.top, 64)
                    .padding(.bottom, 44)

                    // Game cards
                    VStack(spacing: 18) {
                        NavigationLink(destination: TapFrenzyView()) {
                            GameModeCard(
                                title: "TAP FRENZY",
                                description: "Tap as fast as you can. Avoid traps. Beat the clock.",
                                icon: "hand.tap.fill",
                                accentColor: T.accent,
                                bestScore: scoreStore.tapFrenzyBest
                            )
                        }
                        .buttonStyle(CardPressStyle())

                        NavigationLink(destination: LightItUpView()) {
                            GameModeCard(
                                title: "LIGHT IT UP",
                                description: "Light up the grid. Miss it and lose a life.",
                                icon: "bolt.fill",
                                accentColor: T.accent,
                                bestScore: scoreStore.lightItUpBest
                            )
                        }
                        .buttonStyle(CardPressStyle())
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    MadeWithHeartLabel()
                        .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Gradient Background

private struct HomeBackground: View {
    @State private var drift: Bool = false

    var body: some View {
        ZStack {
            // Base
            T.bg.ignoresSafeArea()

            // Top-center spotlight — tall vertical column of accent light
            // bleeds down from the title area like a stage light
            LinearGradient(
                colors: [
                    T.accent.opacity(0.18),
                    T.accent.opacity(0.06),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.55)
            )
            .ignoresSafeArea()

            // Top-left deep violet orb — drifts gently
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.38, green: 0.16, blue: 0.78).opacity(0.45),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 340, height: 300)
                .blur(radius: 70)
                .offset(
                    x: drift ? -130 : -110,
                    y: drift ? -340 : -360
                )
                .animation(
                    .easeInOut(duration: 9).repeatForever(autoreverses: true),
                    value: drift
                )

            // Bottom-right highlight orb
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            T.highlight.opacity(0.25),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 300, height: 280)
                .blur(radius: 65)
                .offset(
                    x: drift ? 140 : 120,
                    y: drift ? 340 : 360
                )
                .animation(
                    .easeInOut(duration: 11).repeatForever(autoreverses: true),
                    value: drift
                )

            // Very subtle noise texture — thin horizontal scan-line shimmer
            // achieved with a near-transparent gradient overlay
            LinearGradient(
                colors: [
                    Color.white.opacity(0.015),
                    Color.clear,
                    Color.white.opacity(0.01),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .blendMode(.screen)
        }
        .onAppear { drift = true }
    }
}

// MARK: - Made With Heart Label

private struct MadeWithHeartLabel: View {
    @State private var heartScale: CGFloat = 1.0
    @State private var glowRadius: CGFloat = 4
    @State private var glowOpacity: Double = 0.6

    private let heartColor = Color(red: 1, green: 0.22, blue: 0.3)

    var body: some View {
        HStack(spacing: 0) {
            Text("Made with ")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.28))

            Image(systemName: "heart.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(heartColor)
                .scaleEffect(heartScale)
                .shadow(color: heartColor.opacity(glowOpacity), radius: glowRadius)

            Text(" by ")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.28))

            Text("Mufli Mohideen")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(T.accent)
        }
        .onAppear { beatLoop() }
    }

    private func beatLoop() {
        withAnimation(.easeOut(duration: 0.12)) {
            heartScale  = 1.35
            glowRadius  = 10
            glowOpacity = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                heartScale  = 1.0
                glowRadius  = 4
                glowOpacity = 0.5
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            withAnimation(.easeOut(duration: 0.10)) {
                heartScale  = 1.22
                glowRadius  = 8
                glowOpacity = 0.9
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) {
                heartScale  = 1.0
                glowRadius  = 4
                glowOpacity = 0.5
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { beatLoop() }
    }
}

// MARK: - Game Mode Card

private struct GameModeCard: View {
    let title: String
    let description: String
    let icon: String
    let accentColor: Color
    let bestScore: Int

    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(accentColor)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(1)
                Text(description)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(T.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            VStack(spacing: 3) {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(T.highlight.opacity(0.8))
                Text("\(bestScore)")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("BEST")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundColor(T.secondary.opacity(0.6))
                    .tracking(2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(T.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(accentColor.opacity(0.45), lineWidth: 1.5)
                )
        )
    }
}

private struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

#Preview {
    HomeView()
        .environmentObject(ScoreStore())
}
