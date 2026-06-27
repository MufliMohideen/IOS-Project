//
//  HomeView.swift
//  ios-project
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var scoreStore: ScoreStore

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.06, green: 0.06, blue: 0.10),
                             Color(red: 0.04, green: 0.04, blue: 0.08)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        Text("TAP ARENA")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(5)
                            .shadow(color: Color(red: 1, green: 0.3, blue: 0.3).opacity(0.5), radius: 14)

                        Text("CHOOSE YOUR GAME")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
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
                                accentColor: Color(red: 0.95, green: 0.25, blue: 0.25),
                                bestScore: scoreStore.tapFrenzyBest
                            )
                        }
                        .buttonStyle(CardPressStyle())

                        NavigationLink(destination: LightItUpView()) {
                            GameModeCard(
                                title: "LIGHT IT UP",
                                description: "Light up the grid. Miss it and lose a life.",
                                icon: "bolt.fill",
                                accentColor: Color(red: 0.2, green: 0.75, blue: 1.0),
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

// MARK: - Made With Heart Label

private struct MadeWithHeartLabel: View {
    @State private var heartScale: CGFloat = 1.0
    @State private var glowRadius: CGFloat = 4
    @State private var glowOpacity: Double = 0.6

    private let heartColor = Color(red: 1, green: 0.22, blue: 0.3)

    var body: some View {
        HStack(spacing: 5) {
            Text("made with")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.22))

            Image(systemName: "heart.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(heartColor)
                .scaleEffect(heartScale)
                .shadow(color: heartColor.opacity(glowOpacity), radius: glowRadius)

            Text("by Mufli Mohideen")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.22))
        }
        .onAppear { beatLoop() }
    }

    private func beatLoop() {
        // First beat — quick pump up
        withAnimation(.easeOut(duration: 0.12)) {
            heartScale  = 1.35
            glowRadius  = 10
            glowOpacity = 1.0
        }
        // Settle back
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                heartScale  = 1.0
                glowRadius  = 4
                glowOpacity = 0.5
            }
        }
        // Second beat (the lub-dub double beat feel)
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
        // Rest, then repeat
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            beatLoop()
        }
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
            // Icon circle
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(accentColor)
            }

            // Text
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(1)
                Text(description)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // Best score
            VStack(spacing: 3) {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.yellow.opacity(0.7))
                Text("\(bestScore)")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                Text("BEST")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(accentColor.opacity(0.22), lineWidth: 1.5)
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
