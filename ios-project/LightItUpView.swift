//
//  LightItUpView.swift
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

// MARK: - Game Gradient Background

private struct GameBackground: View {
    let accentColor: Color
    let secondaryColor: Color
    @State private var drift = false

    var body: some View {
        ZStack {
            T.bg.ignoresSafeArea()

            LinearGradient(
                colors: [accentColor.opacity(0.13), accentColor.opacity(0.04), Color.clear],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.5)
            )
            .ignoresSafeArea()

            Ellipse()
                .fill(RadialGradient(
                    colors: [accentColor.opacity(0.32), Color.clear],
                    center: .center, startRadius: 0, endRadius: 180
                ))
                .frame(width: 300, height: 260)
                .blur(radius: 72)
                .offset(x: drift ? 140 : 120, y: drift ? -300 : -320)
                .animation(.easeInOut(duration: 9).repeatForever(autoreverses: true), value: drift)

            Ellipse()
                .fill(RadialGradient(
                    colors: [secondaryColor.opacity(0.20), Color.clear],
                    center: .center, startRadius: 0, endRadius: 160
                ))
                .frame(width: 260, height: 240)
                .blur(radius: 68)
                .offset(x: drift ? -130 : -110, y: drift ? 360 : 380)
                .animation(.easeInOut(duration: 11).repeatForever(autoreverses: true), value: drift)
        }
        .onAppear { drift = true }
    }
}

// MARK: - Game Level

enum GameLevel: Int, Equatable, CaseIterable {
    case l1 = 1, l2, l3, l4

    var cardCount: Int {
        switch self {
        case .l1: return 3
        case .l2: return 4
        case .l3: return 6
        case .l4: return 9
        }
    }

    var columns: Int {
        switch self {
        case .l1: return 3
        case .l2: return 2
        case .l3: return 3
        case .l4: return 3
        }
    }

    var litWindow: Double {
        switch self {
        case .l1: return 1.5
        case .l2: return 1.2
        case .l3: return 1.0
        case .l4: return 0.8
        }
    }

    var simultaneousLit: Int {
        switch self {
        case .l4: return 2
        default:  return 1
        }
    }

    var glowColor: Color {
        switch self {
        case .l1: return Color(red: 0.25, green: 0.55, blue: 1.0)
        case .l2: return Color(red: 0.15, green: 0.85, blue: 0.95)
        case .l3: return Color(red: 1.0, green: 0.55, blue: 0.1)
        case .l4: return Color(red: 1.0, green: 0.2, blue: 0.2)
        }
    }

    var name: String {
        switch self {
        case .l1: return "LEVEL 1"
        case .l2: return "LEVEL 2"
        case .l3: return "LEVEL 3"
        case .l4: return "LEVEL 4"
        }
    }

    static func forElapsed(_ elapsed: Int) -> GameLevel {
        switch elapsed {
        case 0..<15:  return .l1
        case 15..<30: return .l2
        case 30..<45: return .l3
        default:      return .l4
        }
    }
}

// MARK: - Card Model

struct LitCard: Identifiable, Equatable {
    let id: Int
    var isLit: Bool = false
}

// MARK: - View

struct LightItUpView: View {
    @EnvironmentObject var scoreStore: ScoreStore
    @Environment(\.dismiss) private var dismiss

    @State private var score: Int = 0
    @State private var timeRemaining: Int = 60
    @State private var lives: Int = 3
    @State private var cards: [LitCard] = []
    @State private var isGameActive: Bool = false
    @State private var currentLevel: GameLevel = .l1
    @State private var showLevelUp: Bool = false
    @State private var levelUpLabel: String = ""
    @State private var levelUpColor: Color = .blue
    @State private var isNewHighScore: Bool = false

    @State private var showHelp: Bool = false

    @State private var mainTimer: Timer?
    @State private var litTimer: Timer?

    var elapsed: Int { 60 - timeRemaining }

    var body: some View {
        ZStack {
            GameBackground(
                accentColor: currentLevel.glowColor,
                secondaryColor: T.accent
            )

            if !isGameActive && (timeRemaining == 0 || lives == 0) {
                gameOverView
                    .transition(.opacity)
            } else {
                gamePlayView
                    .transition(.opacity)
            }

            // Level-up flash overlay
            if showLevelUp {
                levelUpOverlay
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isGameActive)
        .animation(.easeInOut(duration: 0.25), value: showLevelUp)
        .navigationBarHidden(true)
        .onAppear { startGame() }
        .onDisappear { stopTimers() }
        .sheet(isPresented: $showHelp) {
            HelpView(game: .lightItUp)
        }
        .onChange(of: showHelp) { isShowing in
            if isShowing {
                mainTimer?.invalidate()
                litTimer?.invalidate()
            } else if isGameActive {
                startMainTimer()
                startLitTimer(for: currentLevel)
            }
        }
    }

    // MARK: - Gameplay View

    var gamePlayView: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("HOME")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .tracking(1)
                    }
                    .foregroundColor(T.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(T.surface)
                            .overlay(Capsule().strokeBorder(T.card, lineWidth: 1))
                    )
                }
                Spacer()

                // Help button
                Button(action: { showHelp = true }) {
                    Image(systemName: "questionmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(T.secondary)
                        .frame(width: 34, height: 34)
                        .background(
                            Circle()
                                .fill(T.surface)
                                .overlay(Circle().strokeBorder(T.card, lineWidth: 1))
                        )
                }
                .padding(.trailing, 8)

                // Level indicator
                Text(currentLevel.name)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(currentLevel.glowColor)
                    .tracking(2)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(currentLevel.glowColor.opacity(0.12))
                            .overlay(Capsule().strokeBorder(currentLevel.glowColor.opacity(0.3), lineWidth: 1))
                    )
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)

            // Stats row: score, lives, timer
            HStack(spacing: 12) {
                // Score
                VStack(spacing: 3) {
                    Text("SCORE")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(T.secondary)
                        .tracking(3)
                    Text("\(score)")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.25), value: score)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(cardBackground(accent: currentLevel.glowColor))

                // Lives
                VStack(spacing: 6) {
                    Text("LIVES")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(T.secondary)
                        .tracking(3)
                    HStack(spacing: 5) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: i < lives ? "heart.fill" : "heart")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(i < lives ? Color(red: 1, green: 0.25, blue: 0.35) : Color.white.opacity(0.2))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(cardBackground(accent: Color(red: 1, green: 0.25, blue: 0.35)))

                // Timer
                VStack(spacing: 3) {
                    Text("TIME")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(T.secondary)
                        .tracking(3)
                    Text("\(timeRemaining)")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(timeRemaining <= 10 ? Color(red: 1, green: 0.25, blue: 0.25) : .white)
                        .contentTransition(.numericText(countsDown: true))
                        .animation(.spring(response: 0.25), value: timeRemaining)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(cardBackground(accent: timeRemaining <= 10 ? Color(red: 1, green: 0.25, blue: 0.25) : .white))
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            Spacer()

            // Card grid
            let cols = Array(repeating: GridItem(.flexible(), spacing: 14), count: currentLevel.columns)
            LazyVGrid(columns: cols, spacing: 14) {
                ForEach(cards) { card in
                    LitCardView(
                        isLit: card.isLit,
                        glowColor: currentLevel.glowColor
                    )
                    .aspectRatio(1.0, contentMode: .fit)
                    .onTapGesture {
                        cardTapped(id: card.id)
                    }
                }
            }
            .padding(.horizontal, 28)
            .animation(.easeInOut(duration: 0.2), value: currentLevel)

            Spacer()
        }
    }

    // MARK: - Card Background Helper

    private func cardBackground(accent: Color) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(T.card)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(accent.opacity(0.35), lineWidth: 1.5)
            )
    }

    // MARK: - Level Up Overlay

    var levelUpOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 12) {
                Text(levelUpLabel)
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(levelUpColor)
                    .tracking(3)
                    .shadow(color: levelUpColor.opacity(0.7), radius: 20)
                Text("GET READY!")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(T.secondary)
                    .tracking(4)
            }
        }
    }

    // MARK: - Game Over View

    var gameOverView: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("HOME")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .tracking(1)
                    }
                    .foregroundColor(T.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(T.surface)
                            .overlay(Capsule().strokeBorder(T.card, lineWidth: 1))
                    )
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)

            Spacer()

            VStack(spacing: 12) {
                Image(systemName: isNewHighScore ? "trophy.fill" : "bolt.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(
                        isNewHighScore
                            ? LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [Color(red: 0.2, green: 0.75, blue: 1), Color(red: 0.1, green: 0.5, blue: 0.9)], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: isNewHighScore ? Color.yellow.opacity(0.5) : Color.cyan.opacity(0.4), radius: 16)

                Text(isNewHighScore ? "NEW BEST!" : "GAME OVER")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(isNewHighScore ? Color.yellow.opacity(0.9) : T.secondary)
                    .tracking(5)
            }
            .padding(.bottom, 28)

            VStack(spacing: 4) {
                Text("\(score)")
                    .font(.system(size: 96, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.75)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.white.opacity(0.15), radius: 20)
                Text("POINTS")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(T.secondary)
                    .tracking(5)
            }

            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundColor(T.highlight.opacity(0.8))
                Text("BEST  \(scoreStore.lightItUpBest)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(T.secondary)
                    .tracking(3)
            }
            .padding(.top, 16)
            .padding(.bottom, 44)

            Button(action: startGame) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .bold))
                    Text("PLAY AGAIN")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .tracking(1)
                }
                .foregroundColor(.black)
                .padding(.horizontal, 48)
                .padding(.vertical, 17)
                .background(
                    Capsule()
                        .fill(Color.white)
                        .shadow(color: Color.white.opacity(0.25), radius: 16, y: 6)
                )
            }

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Logic

    func cardTapped(id: Int) {
        guard isGameActive else { return }
        guard let idx = cards.firstIndex(where: { $0.id == id }) else { return }

        if cards[idx].isLit {
            // Correct tap
            cards[idx].isLit = false
            score += 1
            SoundManager.shared.tapHaptic()
            SoundManager.shared.playTap()
        } else {
            // Wrong tap
            lives = max(0, lives - 1)
            SoundManager.shared.errorHaptic()
            SoundManager.shared.playError()
            if lives == 0 { endGame() }
        }
    }

    func startGame() {
        score = 0
        timeRemaining = 60
        lives = 3
        isNewHighScore = false
        isGameActive = true
        currentLevel = .l1
        rebuildCards(for: .l1)
        startMainTimer()
        startLitTimer(for: .l1)
    }

    func rebuildCards(for level: GameLevel) {
        cards = (0..<level.cardCount).map { LitCard(id: $0) }
    }

    func startMainTimer() {
        mainTimer?.invalidate()
        mainTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard isGameActive else { return }
            if timeRemaining > 0 {
                timeRemaining -= 1
                let newLevel = GameLevel.forElapsed(elapsed)
                if newLevel != currentLevel {
                    transitionToLevel(newLevel)
                }
            } else {
                endGame()
            }
        }
    }

    func startLitTimer(for level: GameLevel) {
        litTimer?.invalidate()
        let window = level.litWindow
        let count = level.simultaneousLit
        let cardCount = level.cardCount

        litTimer = Timer.scheduledTimer(withTimeInterval: window, repeats: true) { _ in
            guard isGameActive else { return }

            // Any still-lit cards that weren't tapped => lose life
            let missedCount = cards.filter { $0.isLit }.count
            if missedCount > 0 {
                lives = max(0, lives - missedCount)
                SoundManager.shared.errorHaptic()
                if lives == 0 {
                    endGame()
                    return
                }
            }

            // Dim all
            for i in cards.indices { cards[i].isLit = false }

            // Light random cards
            var available = Array(0..<cardCount)
            for _ in 0..<min(count, available.count) {
                let pick = Int.random(in: 0..<available.count)
                let idx = available.remove(at: pick)
                if idx < cards.count {
                    cards[idx].isLit = true
                }
            }
        }
    }

    func transitionToLevel(_ newLevel: GameLevel) {
        litTimer?.invalidate()
        // Dim all cards, lose life for missed
        let missedCount = cards.filter { $0.isLit }.count
        if missedCount > 0 {
            lives = max(0, lives - missedCount)
            SoundManager.shared.errorHaptic()
        }

        currentLevel = newLevel
        rebuildCards(for: newLevel)

        levelUpLabel = newLevel.name
        levelUpColor = newLevel.glowColor
        withAnimation { showLevelUp = true }
        SoundManager.shared.successHaptic()
        SoundManager.shared.playSuccess()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { showLevelUp = false }
            if isGameActive { startLitTimer(for: newLevel) }
        }
    }

    func endGame() {
        stopTimers()
        // Dim all
        for i in cards.indices { cards[i].isLit = false }
        isGameActive = false
        SoundManager.shared.playGameOver()
        SoundManager.shared.heavyHaptic()
        if score > scoreStore.lightItUpBest {
            scoreStore.updateLightItUp(score)
            isNewHighScore = true
            SoundManager.shared.successHaptic()
            SoundManager.shared.playSuccess()
        }
    }

    func stopTimers() {
        mainTimer?.invalidate(); mainTimer = nil
        litTimer?.invalidate();  litTimer = nil
    }
}

// MARK: - Lit Card View

private struct LitCardView: View {
    let isLit: Bool
    let glowColor: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(
                isLit
                    ? AnyShapeStyle(LinearGradient(
                        colors: [glowColor.opacity(0.9), glowColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    : AnyShapeStyle(T.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        isLit ? glowColor.opacity(0.8) : T.surface,
                        lineWidth: isLit ? 2 : 1.5
                    )
            )
            .shadow(
                color: isLit ? glowColor.opacity(0.55) : Color.clear,
                radius: isLit ? 16 : 0
            )
            .scaleEffect(isLit ? 1.08 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.6), value: isLit)
    }
}

#Preview {
    LightItUpView()
        .environmentObject(ScoreStore())
}
