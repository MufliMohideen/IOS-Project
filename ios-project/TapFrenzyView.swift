//
//  TapFrenzyView.swift
//  ios-project
//

import SwiftUI

// MARK: - Trap Colour

enum TrapColor: Equatable {
    case red, green, grey

    var colors: [Color] {
        switch self {
        case .red:   return [Color(red: 0.95, green: 0.2, blue: 0.2), Color(red: 0.7, green: 0.0, blue: 0.15)]
        case .green: return [Color(red: 0.1, green: 0.85, blue: 0.4), Color(red: 0.0, green: 0.6, blue: 0.25)]
        case .grey:  return [Color(red: 0.38, green: 0.38, blue: 0.42), Color(red: 0.22, green: 0.22, blue: 0.26)]
        }
    }

    var glowColor: Color {
        switch self {
        case .red:   return Color.red.opacity(0.55)
        case .green: return Color.green.opacity(0.55)
        case .grey:  return Color.gray.opacity(0.35)
        }
    }

    var accentColor: Color {
        switch self {
        case .red:   return Color(red: 1.0, green: 0.35, blue: 0.35)
        case .green: return Color(red: 0.2, green: 1.0, blue: 0.5)
        case .grey:  return Color(red: 0.6, green: 0.6, blue: 0.65)
        }
    }

    var bonusText: String? {
        switch self {
        case .green: return "+2  BONUS"
        case .grey:  return "-1  TRAP"
        default:     return nil
        }
    }
}

// MARK: - Game Mode

enum GameMode: Equatable {
    case normal
    case streak
    case ghost
}

// MARK: - View

struct TapFrenzyView: View {
    @EnvironmentObject var scoreStore: ScoreStore
    @Environment(\.dismiss) private var dismiss

    // Core state
    @State private var score: Int = 0
    @State private var timeRemaining: Int = 10
    @State private var isGameActive: Bool = false
    @State private var gameTimer: Timer?
    @State private var trapTimer: Timer?
    @State private var buttonScale: CGFloat = 1.0
    @State private var trapColor: TrapColor = .red
    @State private var showTrapLabel: Bool = false
    @State private var isNewHighScore: Bool = false

    // Mode
    @State private var gameMode: GameMode = .normal
    @State private var pendingMode: GameMode? = nil
    @State private var showModeSwitchAlert: Bool = false

    // Streak state
    @State private var streakCount: Int = 0
    @State private var lastTapTime: Date? = nil
    @State private var showStreakBurst: Bool = false
    @State private var streakBurstLabel: String = ""

    // Ghost race state
    @State private var ghostScore: Int = 0
    @State private var ghostTimer: Timer? = nil
    @State private var lastRunScorecard: [Int] = []     // current run, built second by second
    @State private var previousRunScorecard: [Int] = [] // last completed run, used by ghost
    @State private var ghostElapsed: Int = 0
    @State private var isAhead: Bool = false

    var streakMultiplier: Int {
        switch streakCount {
        case 0...4:  return 1
        case 5...9:  return 2
        case 10...14: return 3
        default:     return 4
        }
    }

    var streakColor: Color {
        switch streakMultiplier {
        case 1: return .white.opacity(0.5)
        case 2: return Color(red: 0.3, green: 0.8, blue: 1.0)
        case 3: return Color(red: 0.3, green: 1.0, blue: 0.5)
        default: return Color(red: 1.0, green: 0.8, blue: 0.1)
        }
    }

    var buttonSize: CGFloat {
        let fraction = CGFloat(timeRemaining) / 10.0
        return 72 + fraction * 158
    }

    var timerColor: Color {
        if timeRemaining <= 3 { return Color(red: 1.0, green: 0.25, blue: 0.25) }
        if timeRemaining <= 6 { return Color(red: 1.0, green: 0.65, blue: 0.1) }
        return .white
    }

    var isGameOver: Bool { !isGameActive && timeRemaining == 0 }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.06, blue: 0.10),
                         Color(red: 0.04, green: 0.04, blue: 0.08)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            if isGameOver {
                gameOverView.transition(.opacity)
            } else {
                gameView.transition(.opacity)
            }

            // Streak burst popup
            if showStreakBurst {
                streakBurstView
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .allowsHitTesting(false)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: isGameActive)
        .animation(.easeInOut(duration: 0.25), value: showStreakBurst)
        .navigationBarHidden(true)
        .onAppear { startGame() }
        .onDisappear { stopTimers() }
        .alert("Switch Mode?", isPresented: $showModeSwitchAlert) {
            Button("Switch & Restart", role: .destructive) {
                if let next = pendingMode {
                    stopTimers()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        gameMode = next
                    }
                    pendingMode = nil
                    startGame()
                }
            }
            Button("Cancel", role: .cancel) { pendingMode = nil }
        } message: {
            Text("Switching mode will end your current game and restart.")
        }
    }

    // MARK: - Game View

    var gameView: some View {
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
                    .foregroundColor(.white.opacity(0.55))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.07))
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                    )
                }

                Spacer()

                // 3-way mode toggle
                HStack(spacing: 0) {
                    modeButton("NORMAL", mode: .normal)
                    modeButton("STREAK", mode: .streak)
                    modeButton("GHOST",  mode: .ghost)
                }
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.07))
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
            .padding(.bottom, 8)

            // Score card
            VStack(spacing: 6) {
                Text("SCORE")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.45))
                    .tracking(4)

                Text("\(score)")
                    .font(.system(size: 76, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: trapColor.accentColor.opacity(0.5), radius: 14)
                    .frame(minWidth: 140)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.25), value: score)

                // Fixed-height badge row — prevents card resizing as button shrinks
                ZStack {
                    if gameMode == .ghost && isGameActive {
                        let delta = score - ghostScore
                        HStack(spacing: 4) {
                            Image(systemName: delta >= 0 ? "arrow.up" : "arrow.down")
                                .font(.system(size: 10, weight: .bold))
                            Text(delta >= 0 ? "+\(delta) vs ghost" : "\(delta) vs ghost")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(delta >= 0 ? Color(red: 0.2, green: 1.0, blue: 0.5) : Color(red: 1.0, green: 0.35, blue: 0.35))
                        .animation(.easeInOut(duration: 0.3), value: delta)
                    } else if gameMode == .streak && streakCount > 0 {
                        HStack(spacing: 5) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text("\(streakCount) streak  ×\(streakMultiplier)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(streakColor)
                        .animation(.easeInOut(duration: 0.2), value: streakCount)
                    }
                }
                .frame(height: 20)
            }
            .padding(.vertical, 20)
            .frame(width: 280)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .strokeBorder(modeAccentColor.opacity(0.25), lineWidth: 1.5)
                    )
            )
            .padding(.top, 12)

            // Fixed-height ghost bar slot — always occupies space in ghost mode
            ZStack {
                if gameMode == .ghost && isGameActive && !previousRunScorecard.isEmpty {
                    ghostBar
                        .padding(.horizontal, 20)
                }
            }
            .frame(height: gameMode == .ghost ? 28 : 0)
            .padding(.top, gameMode == .ghost ? 10 : 0)

            Spacer()

            // Trap hint pill
            ZStack {
                if showTrapLabel, let label = trapColor.bonusText {
                    HStack(spacing: 6) {
                        Circle().fill(trapColor.accentColor).frame(width: 8, height: 8)
                        Text(label)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(trapColor.accentColor)
                        Circle().fill(trapColor.accentColor).frame(width: 8, height: 8)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(trapColor.accentColor.opacity(0.12))
                            .overlay(Capsule().strokeBorder(trapColor.accentColor.opacity(0.35), lineWidth: 1))
                    )
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
            .frame(height: 36)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: showTrapLabel)
            .padding(.bottom, 16)

            // TAP button
            Button(action: buttonTapped) {
                ZStack {
                    Circle()
                        .fill(trapColor.glowColor.opacity(0.18))
                        .frame(width: buttonSize + 28, height: buttonSize + 28)
                        .blur(radius: 12)

                    Circle()
                        .fill(
                            LinearGradient(colors: trapColor.colors,
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                        )
                        .frame(width: buttonSize, height: buttonSize)
                        .shadow(color: trapColor.glowColor, radius: 22, x: 0, y: 8)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.22), Color.clear],
                                center: .init(x: 0.35, y: 0.3),
                                startRadius: 0,
                                endRadius: buttonSize * 0.55
                            )
                        )
                        .frame(width: buttonSize, height: buttonSize)

                    Circle()
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 2)
                        .frame(width: buttonSize, height: buttonSize)

                    if buttonSize > 110 {
                        VStack(spacing: 2) {
                            Text("TAP")
                                .font(.system(size: buttonSize * 0.148, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                            // Show multiplier inside button when streak active
                            if gameMode == .streak && streakMultiplier > 1 {
                                Text("×\(streakMultiplier)")
                                    .font(.system(size: buttonSize * 0.1, weight: .heavy, design: .rounded))
                                    .foregroundColor(streakColor)
                            } else {
                                Text("ME!")
                                    .font(.system(size: buttonSize * 0.128, weight: .bold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .scaleEffect(buttonScale)
            .animation(.spring(response: 0.28, dampingFraction: 0.5), value: buttonScale)
            .animation(.easeInOut(duration: 0.5), value: buttonSize)
            .animation(.easeInOut(duration: 0.4), value: trapColor.glowColor)
            .disabled(!isGameActive)

            Spacer()

            // Timer bar
            VStack(spacing: 10) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.08))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(
                                colors: [timerColor.opacity(0.9), timerColor],
                                startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat(timeRemaining) / 10.0)
                            .animation(.linear(duration: 0.9), value: timeRemaining)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, 2)

                Text("\(timeRemaining)s")
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundColor(timerColor)
                    .shadow(color: timerColor.opacity(0.45), radius: 10)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.spring(response: 0.25), value: timeRemaining)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .strokeBorder(timerColor.opacity(0.2), lineWidth: 1.5)
                    )
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 52)
        }
    }

    // MARK: - Ghost Bar

    var ghostBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "ghost.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.4))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.07))
                    // Ghost progress
                    let maxScore = max(1, max(score, previousRunScorecard.last ?? 1))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.25))
                        .frame(width: geo.size.width * CGFloat(ghostScore) / CGFloat(maxScore))
                        .animation(.linear(duration: 0.9), value: ghostScore)
                    // Live progress
                    RoundedRectangle(cornerRadius: 3)
                        .fill(isAhead
                              ? Color(red: 0.2, green: 1.0, blue: 0.5).opacity(0.7)
                              : Color(red: 1.0, green: 0.35, blue: 0.35).opacity(0.7))
                        .frame(width: geo.size.width * CGFloat(score) / CGFloat(maxScore))
                        .animation(.linear(duration: 0.1), value: score)
                }
            }
            .frame(height: 5)
            Text("GHOST: \(ghostScore)")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.35))
                .fixedSize()
        }
    }

    // MARK: - Streak Burst View

    var streakBurstView: some View {
        VStack {
            Text(streakBurstLabel)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(streakColor)
                .tracking(1)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color(red: 0.07, green: 0.07, blue: 0.11))
                        .overlay(Capsule().strokeBorder(streakColor.opacity(0.5), lineWidth: 1.5))
                        .shadow(color: streakColor.opacity(0.35), radius: 10)
                )
                .padding(.top, 115)
            Spacer()
        }
    }

    // MARK: - Mode Toggle

    var modeAccentColor: Color {
        switch gameMode {
        case .normal: return trapColor.accentColor
        case .streak: return streakColor
        case .ghost:  return Color(red: 0.55, green: 0.45, blue: 1.0)
        }
    }

    @ViewBuilder
    private func modeButton(_ label: String, mode: GameMode) -> some View {
        let isSelected = gameMode == mode
        Text(label)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .tracking(1)
            .foregroundColor(isSelected ? .black : .white.opacity(0.5))
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(
                isSelected ? AnyView(Capsule().fill(Color.white)) : AnyView(Color.clear)
            )
            .onTapGesture {
                guard mode != gameMode else { return }
                if isGameActive {
                    pendingMode = mode
                    showModeSwitchAlert = true
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        gameMode = mode
                    }
                }
            }
    }

    // MARK: - Game Over View

    var gameOverView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("HOME")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .tracking(1)
                    }
                    .foregroundColor(.white.opacity(0.55))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.07))
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                    )
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.top, 56)

            Spacer()

            VStack(spacing: 12) {
                Image(systemName: isNewHighScore ? "trophy.fill" : "flag.checkered")
                    .font(.system(size: 52))
                    .foregroundStyle(
                        isNewHighScore
                        ? LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [Color.white.opacity(0.6), Color.white.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: isNewHighScore ? Color.yellow.opacity(0.5) : Color.clear, radius: 16)

                Text(isNewHighScore ? "NEW BEST!" : "GAME OVER")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(isNewHighScore ? Color.yellow.opacity(0.9) : Color.white.opacity(0.45))
                    .tracking(5)
            }
            .padding(.bottom, 28)

            VStack(spacing: 4) {
                Text("\(score)")
                    .font(.system(size: 96, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [Color.white, Color.white.opacity(0.75)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: Color.white.opacity(0.15), radius: 20)
                Text("TAPS")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(5)
            }

            // Ghost result card
            if gameMode == .ghost && !previousRunScorecard.isEmpty {
                let prev = previousRunScorecard.last ?? 0
                let delta = score - prev
                let won = delta > 0
                let tied = delta == 0
                let accent: Color = won ? Color(red: 0.2, green: 1.0, blue: 0.5)
                                  : tied ? Color(red: 0.6, green: 0.6, blue: 0.7)
                                  : Color(red: 1.0, green: 0.35, blue: 0.35)
                let icon = won ? "figure.run" : tied ? "equal.circle.fill" : "ghost.fill"
                let headline = won ? "YOU WON!" : tied ? "TIED" : "GHOST WINS"
                let subline = won ? "+\(delta) ahead of your ghost"
                            : tied ? "Exactly matched your last run"
                            : "\(-delta) behind your ghost"

                VStack(spacing: 12) {
                    // Score columns
                    HStack(spacing: 0) {
                        VStack(spacing: 4) {
                            Text("\(score)")
                                .font(.system(size: 36, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                            Text("YOU")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.35))
                                .tracking(3)
                        }
                        .frame(maxWidth: .infinity)

                        Rectangle()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 1, height: 44)

                        VStack(spacing: 4) {
                            Text("\(prev)")
                                .font(.system(size: 36, weight: .heavy, design: .rounded))
                                .foregroundColor(.white.opacity(0.45))
                            Text("GHOST")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.25))
                                .tracking(3)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // Outcome badge
                    HStack(spacing: 6) {
                        Image(systemName: icon)
                            .font(.system(size: 11, weight: .bold))
                        Text(headline)
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .tracking(2)
                    }
                    .foregroundColor(accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(accent.opacity(0.12))
                            .overlay(Capsule().strokeBorder(accent.opacity(0.35), lineWidth: 1))
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(accent.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(accent.opacity(0.35), lineWidth: 1.5))
                )
                .padding(.horizontal, 40)
                .padding(.top, 16)
            }

            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.yellow.opacity(0.7))
                Text("BEST  \(scoreStore.tapFrenzyBest)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.45))
                    .tracking(3)
            }
            .padding(.top, 10)
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
    }

    // MARK: - Logic

    func buttonTapped() {
        guard isGameActive else { return }
        SoundManager.shared.tapHaptic()
        SoundManager.shared.playTap()
        animateButtonPress()

        switch gameMode {
        case .normal:
            applyNormalScore()
        case .streak:
            applyStreakScore()
        case .ghost:
            applyNormalScore()
            withAnimation(.easeInOut(duration: 0.3)) { isAhead = score > ghostScore }
        }
    }

    private func animateButtonPress() {
        withAnimation(.spring(response: 0.15, dampingFraction: 0.4)) { buttonScale = 0.88 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { buttonScale = 1.0 }
        }
    }

    private func applyNormalScore() {
        switch trapColor {
        case .green: score += 2
        case .grey:  score = max(0, score - 1)
        case .red:   score += 1
        }
    }

    private func applyStreakScore() {
        let now = Date()
        let gap: TimeInterval = lastTapTime.map { now.timeIntervalSince($0) } ?? 1.0

        if gap <= 0.5 {
            // Within rhythm — build streak
            streakCount += 1
        } else {
            // Rhythm broken — reset
            if streakCount >= 5 {
                SoundManager.shared.errorHaptic()
            }
            streakCount = 0
        }
        lastTapTime = now

        // Base score with multiplier
        let base: Int
        switch trapColor {
        case .green: base = 2
        case .grey:  base = -1
        case .red:   base = 1
        }
        let earned = base > 0 ? base * streakMultiplier : base
        score = max(0, score + earned)

        // Announce multiplier milestones
        let newMultiplier = streakMultiplier
        if streakCount == 5 || streakCount == 10 || streakCount == 15 {
            SoundManager.shared.successHaptic()
            SoundManager.shared.playSuccess()
            streakBurstLabel = "🔥 ×\(newMultiplier) STREAK!"
            withAnimation { showStreakBurst = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation { showStreakBurst = false }
            }
        }
    }

    // MARK: - Game Lifecycle

    func startGame() {
        // Preserve last completed run as the ghost before resetting
        if !lastRunScorecard.isEmpty {
            previousRunScorecard = lastRunScorecard
        }

        score = 0
        timeRemaining = 10
        trapColor = .red
        showTrapLabel = false
        isNewHighScore = false
        streakCount = 0
        lastTapTime = nil
        showStreakBurst = false
        ghostScore = 0
        ghostElapsed = 0
        isAhead = false
        lastRunScorecard = []
        isGameActive = true
        startGameTimer()
        startTrapTimer()
        if gameMode == .ghost && !previousRunScorecard.isEmpty {
            startGhostTimer()
        }
    }

    func startGameTimer() {
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
                lastRunScorecard.append(score)
                // Break streak if player goes a full second without tapping
                if gameMode == .streak {
                    let gap = lastTapTime.map { Date().timeIntervalSince($0) } ?? 2.0
                    if gap > 1.0 && streakCount > 0 {
                        if streakCount >= 5 { SoundManager.shared.errorHaptic() }
                        streakCount = 0
                    }
                }
            } else {
                lastRunScorecard.append(score)
                stopTimers()
                isGameActive = false
                SoundManager.shared.playGameOver()
                SoundManager.shared.heavyHaptic()
                if score > scoreStore.tapFrenzyBest {
                    scoreStore.updateTapFrenzy(score)
                    isNewHighScore = true
                    SoundManager.shared.successHaptic()
                    SoundManager.shared.playSuccess()
                }
            }
        }
    }

    func startGhostTimer() {
        ghostTimer?.invalidate()
        ghostElapsed = 0
        ghostTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            ghostElapsed += 1
            let idx = min(ghostElapsed - 1, previousRunScorecard.count - 1)
            if idx >= 0 {
                ghostScore = previousRunScorecard[idx]
                withAnimation(.easeInOut(duration: 0.4)) {
                    isAhead = score > ghostScore
                }
            }
            if ghostElapsed >= previousRunScorecard.count {
                ghostTimer?.invalidate()
                ghostTimer = nil
            }
        }
    }

    func startTrapTimer() {
        trapTimer?.invalidate()
        trapTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            guard isGameActive else { return }
            let next = pickNextTrapColor()
            withAnimation(.easeInOut(duration: 0.35)) {
                trapColor = next
                showTrapLabel = next != .red
            }
            if next != .red {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                    withAnimation(.easeOut(duration: 0.25)) { showTrapLabel = false }
                }
            }
        }
    }

    func pickNextTrapColor() -> TrapColor {
        let roll = Int.random(in: 0..<4)
        let candidate: TrapColor = roll < 2 ? .red : (roll == 2 ? .green : .grey)
        return candidate == trapColor ? .red : candidate
    }

    func stopTimers() {
        gameTimer?.invalidate(); gameTimer = nil
        trapTimer?.invalidate(); trapTimer = nil
        ghostTimer?.invalidate(); ghostTimer = nil
    }
}

#Preview {
    TapFrenzyView()
        .environmentObject(ScoreStore())
}
