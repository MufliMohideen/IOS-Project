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
    @State private var showScores = false

    var body: some View {
        NavigationStack {
            ZStack {
                HomeBackground()

                VStack(spacing: 0) {
                    // Top bar
                    HStack {
                        Spacer()
                        Button(action: { showScores = true }) {
                            HStack(spacing: 5) {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 12, weight: .bold))
                                Text("SCORES")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .tracking(1)
                            }
                            .foregroundColor(T.highlight)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(T.highlight.opacity(0.12))
                                    .overlay(Capsule().strokeBorder(T.highlight.opacity(0.35), lineWidth: 1))
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 58)

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
                    .padding(.top, 20)
                    .padding(.bottom, 36)

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

                        NavigationLink(destination: QuizView()) {
                            GameModeCard(
                                title: "QUIZ RUSH",
                                description: "Answer trivia. Beat the clock. Chase your streak.",
                                icon: "questionmark.circle.fill",
                                accentColor: T.accent,
                                bestScore: scoreStore.quizRushBest
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
            .sheet(isPresented: $showScores) {
                HighScoresView(
                    tapBest:     scoreStore.tapFrenzyBest,
                    litBest:     scoreStore.lightItUpBest,
                    quizBest:    scoreStore.quizRushBest,
                    tapHistory:  scoreStore.tapFrenzyHistory,
                    litHistory:  scoreStore.lightItUpHistory,
                    quizHistory: scoreStore.quizRushHistory
                )
            }
        }
    }
}

// MARK: - High Scores View (full sheet)

private struct HighScoresView: View {
    let tapBest:     Int
    let litBest:     Int
    let quizBest:    Int
    let tapHistory:  [ScoreEntry]
    let litHistory:  [ScoreEntry]
    let quizHistory: [ScoreEntry]

    @Environment(\.dismiss) private var dismiss
    @State private var selectedGame: Int = 0

    private let games: [(name: String, icon: String, unit: String)] = [
        ("TAP FRENZY",  "hand.tap.fill",            "TAPS"),
        ("LIGHT IT UP", "bolt.fill",                 "POINTS"),
        ("QUIZ RUSH",   "questionmark.circle.fill",  "POINTS"),
    ]

    private var bestScores: [Int]         { [tapBest, litBest, quizBest] }
    private var histories:  [[ScoreEntry]] { [tapHistory, litHistory, quizHistory] }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            T.bg.ignoresSafeArea()
            LinearGradient(
                colors: [T.accent.opacity(0.11), Color.clear],
                startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.4)
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(T.highlight)
                        .shadow(color: T.highlight.opacity(0.5), radius: 10)
                    Text("HIGH SCORES")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(4)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 36)
                .padding(.bottom, 24)

                // Game selector
                HStack(spacing: 0) {
                    ForEach(games.indices, id: \.self) { i in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedGame = i
                            }
                        }) {
                            VStack(spacing: 5) {
                                Image(systemName: games[i].icon)
                                    .font(.system(size: 16, weight: .bold))
                                Text(games[i].name)
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .tracking(0.5)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .foregroundColor(selectedGame == i ? .black : T.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedGame == i ? T.accent : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 16).fill(T.surface))
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                // Personal best hero
                let best = bestScores[selectedGame]
                let unit = games[selectedGame].unit

                VStack(spacing: 4) {
                    if best == 0 {
                        Text("NO GAMES PLAYED YET")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(T.secondary.opacity(0.5))
                            .tracking(2)
                            .padding(.vertical, 8)
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 13))
                                .foregroundColor(T.highlight)
                            Text("PERSONAL BEST")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(T.highlight)
                                .tracking(2)
                        }
                        Text("\(best)")
                            .font(.system(size: 56, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: T.accent.opacity(0.45), radius: 14)
                            .contentTransition(.numericText())
                        Text(unit)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(T.secondary)
                            .tracking(3)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 16)

                Rectangle()
                    .fill(T.surface)
                    .frame(height: 1)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // History list
                let history = histories[selectedGame]
                if history.isEmpty {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 32))
                            .foregroundColor(T.secondary.opacity(0.35))
                        Text("No history yet — play a game!")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(T.secondary.opacity(0.45))
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(Array(history.enumerated()), id: \.element.id) { idx, entry in
                                HistoryRow(rank: idx + 1, entry: entry, unit: unit, isBest: entry.score == best)
                                if idx < history.count - 1 {
                                    Rectangle()
                                        .fill(T.surface)
                                        .frame(height: 1)
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(T.card)
                                .overlay(RoundedRectangle(cornerRadius: 18)
                                    .strokeBorder(T.accent.opacity(0.18), lineWidth: 1))
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }

            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(T.secondary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(T.surface))
            }
            .padding(.top, 18)
            .padding(.trailing, 22)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedGame)
    }
}

private struct HistoryRow: View {
    let rank: Int
    let entry: ScoreEntry
    let unit: String
    let isBest: Bool

    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isBest ? T.accent.opacity(0.18) : T.surface)
                    .frame(width: 34, height: 34)
                if isBest {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(T.highlight)
                } else {
                    Text("\(rank)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(T.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(formatter.string(from: entry.date))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(T.secondary)
                if isBest {
                    Text("PERSONAL BEST")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(T.accent)
                        .tracking(1)
                }
            }

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(entry.score)")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(isBest ? .white : T.secondary)
                Text(unit.lowercased())
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(T.secondary.opacity(0.6))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
