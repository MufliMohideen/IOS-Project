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

                    Text("v1.0")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.2))
                        .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
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
