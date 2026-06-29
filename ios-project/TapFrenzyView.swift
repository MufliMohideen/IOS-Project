//
//  TapFrenzyView.swift
//  ios-project
//

import SwiftUI
import Combine

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

            // Top-center vertical spotlight
            LinearGradient(
                colors: [accentColor.opacity(0.14), accentColor.opacity(0.04), Color.clear],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.5)
            )
            .ignoresSafeArea()

            // Top-right orb
            Ellipse()
                .fill(RadialGradient(
                    colors: [accentColor.opacity(0.35), Color.clear],
                    center: .center, startRadius: 0, endRadius: 180
                ))
                .frame(width: 300, height: 260)
                .blur(radius: 72)
                .offset(x: drift ? 140 : 120, y: drift ? -300 : -320)
                .animation(.easeInOut(duration: 9).repeatForever(autoreverses: true), value: drift)

            // Bottom-left orb
            Ellipse()
                .fill(RadialGradient(
                    colors: [secondaryColor.opacity(0.22), Color.clear],
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
    @EnvironmentObject var coinStore: CoinStore
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

    // Help
    @State private var showHelp: Bool = false

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
            GameBackground(
                accentColor: modeAccentColor,
                secondaryColor: T.highlight
            )

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
        .sheet(isPresented: $showHelp) {
            HelpView(game: .tapFrenzy)
        }
        .onChange(of: showHelp) { isShowing in
            if isShowing {
                // Pause all timers while help is open
                gameTimer?.invalidate()
                trapTimer?.invalidate()
                ghostTimer?.invalidate()
            } else if isGameActive {
                // Resume — restart each timer that was running
                startGameTimer()
                startTrapTimer()
                if gameMode == .ghost && !previousRunScorecard.isEmpty {
                    startGhostTimer()
                }
            }
        }
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

                // 3-way mode toggle
                HStack(spacing: 0) {
                    modeButton("NORMAL", mode: .normal)
                    modeButton("STREAK", mode: .streak)
                    modeButton("GHOST",  mode: .ghost)
                }
                .background(
                    Capsule()
                        .fill(T.surface)
                        .overlay(Capsule().strokeBorder(T.card, lineWidth: 1))
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
            .padding(.bottom, 8)

            // Score card
            VStack(spacing: 6) {
                Text("SCORE")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(T.secondary)
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
                    .fill(T.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .strokeBorder(modeAccentColor.opacity(0.4), lineWidth: 1.5)
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
                    let useSkin = trapColor == .red
                    let activeSkin = CoinStore.buttonSkins.first(where: { $0.id == coinStore.equippedButtonSkin })
                    let displayColors = useSkin ? (activeSkin?.colors ?? trapColor.colors) : trapColor.colors
                    let displayGlow   = useSkin ? (activeSkin?.glowColor ?? trapColor.glowColor) : trapColor.glowColor
                    let skinID        = useSkin ? coinStore.equippedButtonSkin : "default"

                    // Outer glow halo
                    Circle()
                        .fill(displayGlow.opacity(0.18))
                        .frame(width: buttonSize + 28, height: buttonSize + 28)
                        .blur(radius: 12)

                    // Base gradient (used for all skins as backdrop, hidden by overlay for animated skins)
                    Circle()
                        .fill(LinearGradient(colors: displayColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: buttonSize, height: buttonSize)
                        .shadow(color: displayGlow, radius: 22, x: 0, y: 8)

                    // Animated skin overlay scaled to button size
                    if useSkin && skinID != "default" {
                        TapButtonSkinOverlay(skinID: skinID)
                            .frame(width: buttonSize, height: buttonSize)
                            .clipShape(Circle())
                            .allowsHitTesting(false)
                    } else {
                        // Plain gloss for Classic / trap states
                        Circle()
                            .fill(RadialGradient(colors: [Color.white.opacity(0.22), Color.clear],
                                                 center: .init(x: 0.35, y: 0.3), startRadius: 0, endRadius: buttonSize * 0.55))
                            .frame(width: buttonSize, height: buttonSize)
                    }

                    Circle()
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 2)
                        .frame(width: buttonSize, height: buttonSize)

                    // Label / multiplier overlay
                    if buttonSize > 110 {
                        VStack(spacing: 2) {
                            if gameMode == .streak && streakMultiplier > 1 {
                                Text("×\(streakMultiplier)")
                                    .font(.system(size: buttonSize * 0.1, weight: .heavy, design: .rounded))
                                    .foregroundColor(streakColor)
                            } else if !useSkin || skinID == "default" {
                                Text("TAP")
                                    .font(.system(size: buttonSize * 0.148, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
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
                        RoundedRectangle(cornerRadius: 4).fill(T.surface)
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
                    .fill(T.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .strokeBorder(timerColor.opacity(0.35), lineWidth: 1.5)
                    )
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 52)
        }
    }

    // MARK: - Ghost Bar

    var ghostBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "figure.run")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(T.secondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(T.surface)
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
                .foregroundColor(T.secondary)
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
                        .fill(T.card)
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
        case .ghost:  return T.accent
        }
    }

    @ViewBuilder
    private func modeButton(_ label: String, mode: GameMode) -> some View {
        let isSelected = gameMode == mode
        Text(label)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .tracking(1)
            .foregroundColor(isSelected ? .black : T.secondary)
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
                    .foregroundColor(isNewHighScore ? Color.yellow.opacity(0.9) : T.secondary)
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
                    .shadow(color: T.accent.opacity(0.3), radius: 20)
                Text("TAPS")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(T.secondary)
                    .tracking(5)
            }

            // Ghost result card
            if gameMode == .ghost && !previousRunScorecard.isEmpty {
                let prev = previousRunScorecard.last ?? 0
                let delta = score - prev
                let won = delta > 0
                let tied = delta == 0
                let accent: Color = won ? Color(red: 0.2, green: 1.0, blue: 0.5)
                                  : tied ? T.highlight
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
                                .foregroundColor(T.secondary)
                                .tracking(3)
                        }
                        .frame(maxWidth: .infinity)

                        Rectangle()
                            .fill(T.surface)
                            .frame(width: 1, height: 44)

                        VStack(spacing: 4) {
                            Text("\(prev)")
                                .font(.system(size: 36, weight: .heavy, design: .rounded))
                                .foregroundColor(T.secondary)
                            Text("GHOST")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(T.secondary.opacity(0.6))
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
                    .foregroundColor(T.highlight.opacity(0.8))
                Text("BEST  \(scoreStore.tapFrenzyBest)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(T.secondary)
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
                coinStore.convertScore(tapFrenzy: score)
                scoreStore.updateTapFrenzy(score)
                if score >= scoreStore.tapFrenzyBest {
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

// MARK: - Animated skin overlay for the in-game tap button

private struct TapButtonSkinOverlay: View {
    let skinID: String
    var body: some View {
        switch skinID {
        case "fire":   TapFireOverlay()
        case "galaxy": TapGalaxyOverlay()
        case "neon":   TapNeonOverlay()
        case "gold":   TapGoldOverlay()
        case "ice":    TapIceOverlay()
        case "pirate": TapPirateOverlay()
        default:       EmptyView()
        }
    }
}

// Fire: dense flame particles + ember dots
private struct TapFireOverlay: View {
    @State private var particles: [TapFlame] = []
    @State private var activeIDs: Set<Int> = []
    @State private var glow: Bool = false
    @State private var isRunning = false
    private let fast  = Timer.publish(every: 0.09, on: .main, in: .common).autoconnect()
    private let ember = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Circle().fill(Color(red:1,green:0.3,blue:0).opacity(0.35)).blur(radius: glow ? 20 : 12)
                .animation(.easeInOut(duration: 0.18).repeatForever(autoreverses: true), value: glow)
            Circle().fill(RadialGradient(colors:[Color.white.opacity(glow ? 0.4:0.12), Color.clear], center:.center, startRadius:0, endRadius:60))
                .animation(.easeInOut(duration: 0.12).repeatForever(autoreverses: true), value: glow)
            ForEach(particles.filter { activeIDs.contains($0.id) }) { p in TapFlameView(p: p) }
        }
        .onAppear { isRunning = true; glow = true; for i in 0..<10 { DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)*0.05) { spawn(false) } } }
        .onDisappear { isRunning = false }
        .onReceive(fast)  { _ in if isRunning { spawn(false) } }
        .onReceive(ember) { _ in if isRunning { spawn(true) } }
    }
    private func spawn(_ isEmber: Bool) {
        let id = Int.random(in: 0..<1_000_000)
        let p  = TapFlame(id:id, x:CGFloat.random(in:-60...60), drift:CGFloat.random(in:-20...20),
                          size:isEmber ? CGFloat.random(in:4...8) : CGFloat.random(in:20...44),
                          dur:Double.random(in:0.45...0.8), isEmber:isEmber)
        particles.append(p); activeIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + p.dur + 0.1) { activeIDs.remove(id); particles.removeAll { $0.id == id } }
    }
}
private struct TapFlame: Identifiable { let id:Int; let x:CGFloat; let drift:CGFloat; let size:CGFloat; let dur:Double; let isEmber:Bool }
private struct TapFlameView: View {
    let p: TapFlame; @State private var y: CGFloat = 30; @State private var x: CGFloat = 0; @State private var opacity: Double = 0
    var body: some View {
        Group {
            if p.isEmber { Circle().fill(RadialGradient(colors:[Color.white,Color.yellow,Color.orange.opacity(0)], center:.center, startRadius:0, endRadius:p.size/2)).frame(width:p.size,height:p.size) }
            else { Ellipse().fill(RadialGradient(colors:[Color.white.opacity(0.9),Color.yellow.opacity(0.7),Color.orange.opacity(0.4),Color.clear], center:.center, startRadius:0, endRadius:p.size*0.5)).frame(width:p.size*0.6,height:p.size).blur(radius:3) }
        }
        .opacity(opacity).offset(x:x, y:y)
        .onAppear {
            x = p.x
            withAnimation(.easeOut(duration:0.08)) { opacity = 0.85 }
            withAnimation(.easeOut(duration:p.dur)) { y = CGFloat.random(in:-110 ... -55); x = p.x + p.drift }
            withAnimation(.easeIn(duration:0.25).delay(p.dur*0.65)) { opacity = 0 }
        }
    }
}

// Galaxy: warp stars + spinning accretion disk
private struct TapGalaxyOverlay: View {
    @State private var stars: [TapStar] = []
    @State private var activeIDs: Set<Int> = []
    @State private var diskSpin: Double = 0
    @State private var isRunning = false
    private let timer = Timer.publish(every: 0.07, on: .main, in: .common).autoconnect()
    private let colors: [Color] = [.white, Color(red:0.88,green:0.75,blue:1), Color(red:0.55,green:0.88,blue:1), Color(red:0.65,green:0.45,blue:1)]

    var body: some View {
        ZStack {
            ForEach(0..<4) { i in
                Ellipse().fill(AngularGradient(colors:[Color(red:0.6,green:0.15,blue:1).opacity(0.25),Color.clear], center:.center))
                    .frame(width:160,height:40).blur(radius:8).rotationEffect(.degrees(diskSpin*0.5 + Double(i)*90))
            }
            ForEach(stars.filter { activeIDs.contains($0.id) }) { s in TapStarView(star:s) }
        }
        .onAppear { isRunning = true; withAnimation(.linear(duration:6).repeatForever(autoreverses:false)) { diskSpin = 360 }
            for i in 0..<12 { DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)*0.06) { spawn() } } }
        .onDisappear { isRunning = false }
        .onReceive(timer) { _ in if isRunning { spawn() } }
    }
    private func spawn() {
        let id = Int.random(in: 0..<1_000_000); let spd = Double.random(in: 0.35...0.7)
        let s  = TapStar(id:id, angle:Double.random(in:0..<360), speed:spd, startR:CGFloat.random(in:2...12), size:CGFloat.random(in:1.5...4.5), color:colors.randomElement()!)
        stars.append(s); activeIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + spd + 0.1) { activeIDs.remove(id); stars.removeAll { $0.id == id } }
    }
}
private struct TapStar: Identifiable { let id:Int; let angle:Double; let speed:Double; let startR:CGFloat; let size:CGFloat; let color:Color }
private struct TapStarView: View {
    let star: TapStar; @State private var progress: CGFloat = 0; @State private var opacity: Double = 0
    private let endR: CGFloat = 100
    var body: some View {
        let rad       = star.angle * Double.pi / 180
        let cosR      = CGFloat(cos(rad))
        let sinR      = CGFloat(sin(rad))
        let tailDist  = star.startR + (endR - star.startR) * progress * 0.72
        let headDist  = star.startR + (endR - star.startR) * progress
        let tailW     = max(1, (endR - star.startR) * progress * 0.5)
        let tailH     = max(0.5, star.size * 0.4)
        ZStack {
            Capsule()
                .fill(LinearGradient(colors: [star.color.opacity(0), star.color.opacity(0.55 * opacity)], startPoint: .leading, endPoint: .trailing))
                .frame(width: tailW, height: tailH)
                .offset(x: cosR * tailDist, y: sinR * tailDist)
                .rotationEffect(.degrees(star.angle))
            Circle()
                .fill(RadialGradient(colors: [Color.white, star.color.opacity(0.5), .clear], center: .center, startRadius: 0, endRadius: star.size))
                .frame(width: star.size * 2, height: star.size * 2)
                .opacity(opacity)
                .offset(x: cosR * headDist, y: sinR * headDist)
        }
        .onAppear {
            withAnimation(.easeIn(duration:0.08)) { opacity = 1 }
            withAnimation(.easeIn(duration:star.speed)) { progress = 1 }
            withAnimation(.easeOut(duration:0.2).delay(star.speed*0.8)) { opacity = 0 }
        }
    }
}

// Neon: jagged bolts crackling across the button
private struct TapNeonOverlay: View {
    @State private var bolts: [TapBolt] = []
    @State private var activeIDs: Set<Int> = []
    @State private var isRunning = false
    private let boltTimer  = Timer.publish(every: 0.11, on: .main, in: .common).autoconnect()
    private let shockTimer = Timer.publish(every: 0.7,  on: .main, in: .common).autoconnect()
    @State private var shockScale: CGFloat = 1; @State private var shockOpacity: Double = 0

    var body: some View {
        ZStack {
            Circle().strokeBorder(Color.cyan.opacity(shockOpacity), lineWidth: 2).scaleEffect(shockScale)
            ForEach(bolts.filter { activeIDs.contains($0.id) }) { b in TapBoltView(bolt:b) }
        }
        .onAppear { isRunning = true; emitShock(); for i in 0..<6 { DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)*0.08) { spawn() } } }
        .onDisappear { isRunning = false }
        .onReceive(boltTimer)  { _ in if isRunning { spawn() } }
        .onReceive(shockTimer) { _ in if isRunning { emitShock() } }
    }
    private func emitShock() {
        shockScale = 1; shockOpacity = 0.85
        withAnimation(.easeOut(duration: 0.65)) { shockScale = 1.4; shockOpacity = 0 }
    }
    private func spawn() {
        let id = Int.random(in: 0..<1_000_000); let angle = Double.random(in:0..<360); let rad = angle * .pi / 180
        let segs = Int.random(in:3...5); var pts = [CGPoint(x:0,y:0)]
        let len: CGFloat = CGFloat.random(in:40...90); let segLen = len/CGFloat(segs)
        for seg in 1...segs {
            let along = segLen*CGFloat(seg); let jag: CGFloat = seg==segs ? 1 : CGFloat.random(in:-14...14)
            pts.append(CGPoint(x:cos(rad + .pi/2)*jag + cos(rad)*along, y:sin(rad + .pi/2)*jag + sin(rad)*along))
        }
        let b = TapBolt(id:id, points:pts, duration:Double.random(in:0.08...0.18), color:Bool.random() ? .white : Color(red:0.4,green:1,blue:1), width:CGFloat.random(in:1...2))
        bolts.append(b); activeIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + b.duration + 0.05) { activeIDs.remove(id); bolts.removeAll { $0.id == id } }
    }
}
private struct TapBolt: Identifiable { let id:Int; let points:[CGPoint]; let duration:Double; let color:Color; let width:CGFloat }
private struct TapBoltView: View {
    let bolt: TapBolt; @State private var opacity: Double = 0
    var body: some View {
        ZStack {
            TapBoltPath(points:bolt.points).stroke(bolt.color.opacity(0.45), lineWidth:bolt.width+4).blur(radius:3).opacity(opacity)
            TapBoltPath(points:bolt.points).stroke(bolt.color, style:StrokeStyle(lineWidth:bolt.width, lineCap:.round, lineJoin:.round)).opacity(opacity)
        }
        .onAppear { opacity = 1; withAnimation(.easeIn(duration:bolt.duration*0.75).delay(bolt.duration*0.25)) { opacity = 0 } }
    }
}
private struct TapBoltPath: Shape {
    let points: [CGPoint]
    func path(in rect: CGRect) -> Path {
        var p = Path(); guard points.count > 1 else { return p }
        p.move(to: CGPoint(x:rect.midX+points[0].x, y:rect.midY+points[0].y))
        for pt in points.dropFirst() { p.addLine(to: CGPoint(x:rect.midX+pt.x, y:rect.midY+pt.y)) }
        return p
    }
}

// Gold: rising coins + rotating shine
private struct TapGoldOverlay: View {
    @State private var particles: [TapGoldP] = []
    @State private var activeIDs: Set<Int> = []
    @State private var shineAngle: Double = 0
    @State private var isRunning = false
    private let timer = Timer.publish(every: 0.09, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Capsule().fill(LinearGradient(colors:[Color.clear,Color.white.opacity(0.55),Color.clear], startPoint:.leading, endPoint:.trailing))
                .frame(width:200, height:4).rotationEffect(.degrees(shineAngle)).blendMode(.screen)
            ForEach(particles.filter { activeIDs.contains($0.id) }) { p in TapGoldView(p:p) }
        }
        .onAppear { isRunning = true; withAnimation(.linear(duration:2.2).repeatForever(autoreverses:false)) { shineAngle = 180 }
            for i in 0..<8 { DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)*0.07) { spawn() } } }
        .onDisappear { isRunning = false }
        .onReceive(timer) { _ in if isRunning { spawn() } }
    }
    private func spawn() {
        let id = Int.random(in: 0..<1_000_000); let roll = Int.random(in:0..<3)
        let p  = TapGoldP(id:id, x:CGFloat.random(in:-70...70), size: roll==0 ? CGFloat.random(in:8...14) : CGFloat.random(in:3...7), dur:Double.random(in:0.5...1.0), isCoin:roll==0)
        particles.append(p); activeIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + p.dur + 0.1) { activeIDs.remove(id); particles.removeAll { $0.id == id } }
    }
}
private struct TapGoldP: Identifiable { let id:Int; let x:CGFloat; let size:CGFloat; let dur:Double; let isCoin:Bool }
private struct TapGoldView: View {
    let p: TapGoldP; @State private var y: CGFloat = 20; @State private var opacity: Double = 0; @State private var rotation: Double = 0
    var body: some View {
        Group {
            if p.isCoin {
                ZStack {
                    Ellipse().fill(LinearGradient(colors:[Color(red:1,green:0.97,blue:0.45),Color(red:0.88,green:0.62,blue:0)], startPoint:.topLeading, endPoint:.bottomTrailing)).frame(width:p.size*0.65, height:p.size)
                    Ellipse().strokeBorder(Color(red:0.55,green:0.32,blue:0).opacity(0.5), lineWidth:0.8).frame(width:p.size*0.65, height:p.size)
                }
            } else {
                ZStack { ForEach(0..<4) { i in Capsule().fill(Color.white.opacity(0.9)).frame(width:p.size*1.8,height:1.2).rotationEffect(.degrees(Double(i)*45+rotation)) } }
            }
        }
        .rotationEffect(.degrees(rotation)).opacity(opacity).offset(x:p.x, y:y)
        .onAppear {
            withAnimation(.easeOut(duration:0.08)) { opacity = 1 }
            withAnimation(.easeOut(duration:p.dur)) { y = CGFloat.random(in:-120 ... -55); rotation = Double.random(in:180...540) }
            withAnimation(.easeIn(duration:0.22).delay(p.dur*0.68)) { opacity = 0 }
        }
    }
}

// Ice: blizzard crystals + snowflake
private struct TapIceOverlay: View {
    @State private var particles: [TapIceP] = []
    @State private var activeIDs: Set<Int> = []
    @State private var snowAngle: Double = 0
    @State private var isRunning = false
    private let timer = Timer.publish(every: 0.09, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            ZStack {
                ForEach(0..<6) { i in
                    Capsule().fill(Color.white.opacity(0.7)).frame(width:28,height:2).offset(x:14).rotationEffect(.degrees(Double(i)*60+snowAngle))
                    Capsule().fill(Color.white.opacity(0.5)).frame(width:10,height:1).offset(x:20).rotationEffect(.degrees(Double(i)*60+snowAngle+35))
                    Capsule().fill(Color.white.opacity(0.5)).frame(width:10,height:1).offset(x:20).rotationEffect(.degrees(Double(i)*60+snowAngle-35))
                }
                Circle().fill(Color.white).frame(width:6,height:6).shadow(color:Color(red:0.5,green:0.9,blue:1),radius:4)
            }
            ForEach(particles.filter { activeIDs.contains($0.id) }) { p in TapIceView(p:p) }
        }
        .onAppear { isRunning = true; withAnimation(.linear(duration:7).repeatForever(autoreverses:false)) { snowAngle = 360 }
            for i in 0..<10 { DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)*0.07) { spawn() } } }
        .onDisappear { isRunning = false }
        .onReceive(timer) { _ in if isRunning { spawn() } }
    }
    private func spawn() {
        let id = Int.random(in: 0..<1_000_000); let sx = CGFloat.random(in:-80...80); let sy = CGFloat.random(in:-80...80); let drift = CGFloat.random(in:15...30)
        let p  = TapIceP(id:id, sx:sx, sy:sy, ex:sx+drift, ey:sy+drift, size:CGFloat.random(in:2...6), dur:Double.random(in:0.5...1.0))
        particles.append(p); activeIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + p.dur + 0.1) { activeIDs.remove(id); particles.removeAll { $0.id == id } }
    }
}
private struct TapIceP: Identifiable { let id:Int; let sx:CGFloat; let sy:CGFloat; let ex:CGFloat; let ey:CGFloat; let size:CGFloat; let dur:Double }
private struct TapIceView: View {
    let p: TapIceP; @State private var x: CGFloat = 0; @State private var y: CGFloat = 0; @State private var opacity: Double = 0
    var body: some View {
        Circle().fill(Color.white.opacity(0.85)).frame(width:p.size, height:p.size).opacity(opacity).offset(x:x, y:y)
        .onAppear {
            x = p.sx; y = p.sy
            withAnimation(.easeIn(duration:0.1)) { opacity = 0.9 }
            withAnimation(.linear(duration:p.dur)) { x = p.ex; y = p.ey }
            withAnimation(.easeOut(duration:0.25).delay(p.dur*0.72)) { opacity = 0 }
        }
    }
}

// Pirate: cannonballs + storm flash
private struct TapPirateOverlay: View {
    @State private var cannonballs: [TapCB] = []
    @State private var activeIDs: Set<Int> = []
    @State private var stormFlash: Double = 0
    @State private var isRunning = false
    private let cbTimer    = Timer.publish(every: 0.5,  on: .main, in: .common).autoconnect()
    private let stormTimer = Timer.publish(every: 1.6,  on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Circle().fill(Color(red:0.7,green:0.4,blue:1).opacity(stormFlash)).blendMode(.screen)
            ForEach(cannonballs.filter { activeIDs.contains($0.id) }) { cb in TapCBView(cb:cb) }
        }
        .onAppear { isRunning = true; triggerStorm(); for i in 0..<2 { DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)*0.3) { spawn() } } }
        .onDisappear { isRunning = false }
        .onReceive(cbTimer)    { _ in if isRunning { spawn() } }
        .onReceive(stormTimer) { _ in if isRunning { triggerStorm() } }
    }
    private func triggerStorm() {
        stormFlash = 0
        withAnimation(.easeOut(duration:0.04)) { stormFlash = 0.4 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { withAnimation(.easeOut(duration:0.06)) { stormFlash = 0.05 } }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) { withAnimation(.easeOut(duration:0.04)) { stormFlash = 0.3 } }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) { withAnimation(.easeIn(duration:0.25)) { stormFlash = 0 } }
    }
    private func spawn() {
        let id = Int.random(in: 0..<1_000_000); let angle = Double.random(in:0..<360); let rad = angle * .pi / 180
        let cb = TapCB(id:id, sx:cos(rad)*90, sy:sin(rad)*90, angle:angle+180, speed:Double.random(in:0.35...0.6))
        cannonballs.append(cb); activeIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + cb.speed + 0.1) { activeIDs.remove(id); cannonballs.removeAll { $0.id == id } }
    }
}
private struct TapCB: Identifiable { let id:Int; let sx:CGFloat; let sy:CGFloat; let angle:Double; let speed:Double }
private struct TapCBView: View {
    let cb: TapCB; @State private var x: CGFloat = 0; @State private var y: CGFloat = 0; @State private var opacity: Double = 0
    var body: some View {
        let rad  = cb.angle * Double.pi / 180
        let cosR = CGFloat(cos(rad))
        let sinR = CGFloat(sin(rad))
        ZStack {
            Capsule().fill(Color(red:0.5,green:0.4,blue:0.55).opacity(0.4)).frame(width:24,height:3)
                .rotationEffect(.degrees(cb.angle+90)).blur(radius:1.5)
                .offset(x: x - cosR * 12, y: y - sinR * 12)
            Circle().fill(RadialGradient(colors:[Color(red:0.55,green:0.55,blue:0.6),Color(red:0.2,green:0.2,blue:0.22)], center:.init(x:0.35,y:0.3), startRadius:0, endRadius:5))
                .frame(width:10, height:10).offset(x:x, y:y)
        }
        .opacity(opacity)
        .onAppear {
            x = cb.sx; y = cb.sy
            withAnimation(.easeIn(duration:0.08)) { opacity = 1 }
            withAnimation(.linear(duration:cb.speed)) { x = cb.sx + cosR * 180; y = cb.sy + sinR * 180 }
            withAnimation(.easeIn(duration:0.2).delay(cb.speed*0.75)) { opacity = 0 }
        }
    }
}

#Preview {
    TapFrenzyView()
        .environmentObject(ScoreStore())
        .environmentObject(CoinStore())
}
