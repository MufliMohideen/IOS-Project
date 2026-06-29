//
//  LightItUpView.swift
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
    @EnvironmentObject var coinStore: CoinStore
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
                    let tileSkin = CoinStore.tileSkins.first(where: { $0.id == coinStore.equippedTileSkin })
                    LitCardView(
                        isLit: card.isLit,
                        glowColor: currentLevel.glowColor,
                        tileSkin: tileSkin
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
        coinStore.convertScore(lightItUp: score)
        scoreStore.updateLightItUp(score)
        if score >= scoreStore.lightItUpBest {
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
    var tileSkin: TileSkin? = nil

    var body: some View {
        let activeGlow = tileSkin?.glowColor ?? glowColor
        let activeLitColors = tileSkin?.litColors ?? [glowColor.opacity(0.9), glowColor.opacity(0.6)]

        ZStack {
            // Unlit base
            RoundedRectangle(cornerRadius: 18)
                .fill(isLit ? AnyShapeStyle(LinearGradient(colors: activeLitColors, startPoint: .topLeading, endPoint: .bottomTrailing)) : AnyShapeStyle(T.card))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(isLit ? activeGlow.opacity(0.8) : T.surface, lineWidth: isLit ? 2 : 1.5))
                .shadow(color: isLit ? activeGlow.opacity(0.55) : Color.clear, radius: isLit ? 16 : 0)

            // Animated skin overlay when lit
            if isLit, let skin = tileSkin {
                LitTileSkinOverlay(skinID: skin.id)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .allowsHitTesting(false)
            }
        }
        .scaleEffect(isLit ? 1.08 : 1.0)
        .animation(.spring(response: 0.28, dampingFraction: 0.6), value: isLit)
    }
}

// Animated overlay rendered on top of the lit tile gradient
private struct LitTileSkinOverlay: View {
    let skinID: String
    var body: some View {
        switch skinID {
        case "fire":   FireTileOverlay()
        case "galaxy": GalaxyTileOverlay()
        case "neon":   NeonTileOverlay()
        case "gold":   GoldTileOverlay()
        case "ice":    IceTileOverlay()
        case "pirate": PirateTileOverlay()
        default:       EmptyView()
        }
    }
}

// Fire: flame particles rising from base
private struct FireTileOverlay: View {
    @State private var particles: [LitFlameParticle] = []
    @State private var activeIDs: Set<Int> = []
    @State private var isRunning = false
    private let fastTimer  = Timer.publish(every: 0.09, on: .main, in: .common).autoconnect()
    private let emberTimer = Timer.publish(every: 0.16, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            ForEach(particles.filter { activeIDs.contains($0.id) }) { p in LitFlameView(p: p) }
        }
        .onAppear { isRunning = true; for i in 0..<6 { DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)*0.05) { spawn(isEmber: false) } } }
        .onDisappear { isRunning = false }
        .onReceive(fastTimer)  { _ in if isRunning { spawn(isEmber: false) } }
        .onReceive(emberTimer) { _ in if isRunning { spawn(isEmber: true) } }
    }
    private func spawn(isEmber: Bool) {
        let id = Int.random(in: 0..<1_000_000)
        let p  = LitFlameParticle(id: id, x: CGFloat.random(in: -30...30), drift: CGFloat.random(in: -12...12),
                                  size: isEmber ? CGFloat.random(in: 3...6) : CGFloat.random(in: 12...26),
                                  duration: Double.random(in: 0.4...0.75), isEmber: isEmber)
        particles.append(p); activeIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + p.duration + 0.1) { activeIDs.remove(id); particles.removeAll { $0.id == id } }
    }
}
private struct LitFlameParticle: Identifiable { let id: Int; let x: CGFloat; let drift: CGFloat; let size: CGFloat; let duration: Double; let isEmber: Bool }
private struct LitFlameView: View {
    let p: LitFlameParticle
    @State private var y: CGFloat = 18; @State private var x: CGFloat = 0; @State private var opacity: Double = 0
    var body: some View {
        Group {
            if p.isEmber {
                Circle().fill(RadialGradient(colors: [Color.white, Color.yellow, Color.orange.opacity(0)], center: .center, startRadius: 0, endRadius: p.size/2))
                    .frame(width: p.size, height: p.size)
            } else {
                Ellipse().fill(RadialGradient(colors: [Color.white.opacity(0.9), Color.yellow.opacity(0.7), Color.orange.opacity(0.4), Color.clear], center: .center, startRadius: 0, endRadius: p.size * 0.5))
                    .frame(width: p.size * 0.6, height: p.size).blur(radius: 2)
            }
        }
        .opacity(opacity).offset(x: x, y: y)
        .onAppear {
            x = p.x
            withAnimation(.easeOut(duration: 0.08)) { opacity = 0.85 }
            withAnimation(.easeOut(duration: p.duration)) { y = CGFloat.random(in: -40 ... -20); x = p.x + p.drift }
            withAnimation(.easeIn(duration: 0.25).delay(p.duration * 0.65)) { opacity = 0 }
        }
    }
}

// Galaxy: warp stars zooming outward
private struct GalaxyTileOverlay: View {
    @State private var stars: [LitStar] = []
    @State private var activeIDs: Set<Int> = []
    @State private var isRunning = false
    private let timer = Timer.publish(every: 0.08, on: .main, in: .common).autoconnect()
    private let colors: [Color] = [.white, Color(red:0.88,green:0.75,blue:1), Color(red:0.55,green:0.88,blue:1)]

    var body: some View {
        ZStack { ForEach(stars.filter { activeIDs.contains($0.id) }) { s in LitStarView(star: s) } }
        .onAppear { isRunning = true; for i in 0..<8 { DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)*0.06) { spawn() } } }
        .onDisappear { isRunning = false }
        .onReceive(timer) { _ in if isRunning { spawn() } }
    }
    private func spawn() {
        let id = Int.random(in: 0..<1_000_000); let spd = Double.random(in: 0.35...0.7)
        let s  = LitStar(id: id, angle: Double.random(in: 0..<360), speed: spd, startR: CGFloat.random(in: 2...8), size: CGFloat.random(in: 1...3), color: colors.randomElement()!)
        stars.append(s); activeIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + spd + 0.1) { activeIDs.remove(id); stars.removeAll { $0.id == id } }
    }
}
private struct LitStar: Identifiable { let id: Int; let angle: Double; let speed: Double; let startR: CGFloat; let size: CGFloat; let color: Color }
private struct LitStarView: View {
    let star: LitStar
    @State private var progress: CGFloat = 0; @State private var opacity: Double = 0
    private let endR: CGFloat = 42
    var body: some View {
        let rad = star.angle * Double.pi / 180
        ZStack {
            Capsule().fill(LinearGradient(colors: [star.color.opacity(0), star.color.opacity(0.5 * opacity)], startPoint: .leading, endPoint: .trailing))
                .frame(width: max(1,(endR-star.startR)*progress*0.5), height: max(0.5,star.size*0.4))
                .offset(x: CGFloat(cos(rad)) * (star.startR+(endR-star.startR)*progress*0.72),
                        y: CGFloat(sin(rad)) * (star.startR+(endR-star.startR)*progress*0.72))
                .rotationEffect(.degrees(star.angle))
            Circle().fill(RadialGradient(colors:[Color.white,star.color.opacity(0.5),.clear], center:.center, startRadius:0, endRadius:star.size))
                .frame(width: star.size*2, height: star.size*2).opacity(opacity)
                .offset(x: CGFloat(cos(rad)) * (star.startR+(endR-star.startR)*progress),
                        y: CGFloat(sin(rad)) * (star.startR+(endR-star.startR)*progress))
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.08)) { opacity = 1 }
            withAnimation(.easeIn(duration: star.speed)) { progress = 1 }
            withAnimation(.easeOut(duration: 0.2).delay(star.speed*0.8)) { opacity = 0 }
        }
    }
}

// Neon: rapid lightning bolts crackling
private struct NeonTileOverlay: View {
    @State private var bolts: [LitBolt] = []
    @State private var activeIDs: Set<Int> = []
    @State private var isRunning = false
    private let timer = Timer.publish(every: 0.11, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack { ForEach(bolts.filter { activeIDs.contains($0.id) }) { b in LitBoltView(bolt: b) } }
        .onAppear { isRunning = true; for i in 0..<4 { DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)*0.08) { spawn() } } }
        .onDisappear { isRunning = false }
        .onReceive(timer) { _ in if isRunning { spawn() } }
    }
    private func spawn() {
        let id    = Int.random(in: 0..<1_000_000)
        let angle = Double.random(in: 0..<360); let rad = angle * .pi / 180
        let segs  = Int.random(in: 3...5); var pts = [CGPoint(x:0,y:0)]
        let len: CGFloat = CGFloat.random(in: 20...32); let segLen = len / CGFloat(segs)
        for seg in 1...segs {
            let along = segLen * CGFloat(seg)
            let jag: CGFloat = seg == segs ? 1 : CGFloat.random(in: -8...8)
            pts.append(CGPoint(x: cos(rad + .pi/2)*jag + cos(rad)*along, y: sin(rad + .pi/2)*jag + sin(rad)*along))
        }
        let b = LitBolt(id: id, points: pts, duration: Double.random(in: 0.08...0.18),
                        color: Bool.random() ? .white : Color(red:0,green:0.95,blue:0.75), width: CGFloat.random(in: 1...1.6))
        bolts.append(b); activeIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + b.duration + 0.05) { activeIDs.remove(id); bolts.removeAll { $0.id == id } }
    }
}
private struct LitBolt: Identifiable { let id: Int; let points: [CGPoint]; let duration: Double; let color: Color; let width: CGFloat }
private struct LitBoltView: View {
    let bolt: LitBolt; @State private var opacity: Double = 0
    var body: some View {
        ZStack {
            LitBoltPath(points: bolt.points).stroke(bolt.color.opacity(0.4), lineWidth: bolt.width+3).blur(radius: 2.5).opacity(opacity)
            LitBoltPath(points: bolt.points).stroke(bolt.color, style: StrokeStyle(lineWidth: bolt.width, lineCap: .round, lineJoin: .round)).opacity(opacity)
        }
        .onAppear { opacity = 1; withAnimation(.easeIn(duration: bolt.duration*0.75).delay(bolt.duration*0.25)) { opacity = 0 } }
    }
}
private struct LitBoltPath: Shape {
    let points: [CGPoint]
    func path(in rect: CGRect) -> Path {
        var p = Path(); guard points.count > 1 else { return p }
        p.move(to: CGPoint(x: rect.midX + points[0].x, y: rect.midY + points[0].y))
        for pt in points.dropFirst() { p.addLine(to: CGPoint(x: rect.midX + pt.x, y: rect.midY + pt.y)) }
        return p
    }
}

// Gold: rising coin particles + shine streak
private struct GoldTileOverlay: View {
    @State private var particles: [LitGoldParticle] = []
    @State private var activeIDs: Set<Int> = []
    @State private var shineAngle: Double = 0
    @State private var isRunning = false
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Capsule().fill(LinearGradient(colors: [Color.clear, Color.white.opacity(0.5), Color.clear], startPoint: .leading, endPoint: .trailing))
                .frame(width: 80, height: 2.5).rotationEffect(.degrees(shineAngle)).blendMode(.screen)
            ForEach(particles.filter { activeIDs.contains($0.id) }) { p in LitGoldView(p: p) }
        }
        .onAppear { isRunning = true; withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) { shineAngle = 180 }
            for i in 0..<5 { DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)*0.08) { spawn() } } }
        .onDisappear { isRunning = false }
        .onReceive(timer) { _ in if isRunning { spawn() } }
    }
    private func spawn() {
        let id = Int.random(in: 0..<1_000_000)
        let p  = LitGoldParticle(id: id, x: CGFloat.random(in: -30...30), size: CGFloat.random(in: 4...8), duration: Double.random(in: 0.5...0.9))
        particles.append(p); activeIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + p.duration + 0.1) { activeIDs.remove(id); particles.removeAll { $0.id == id } }
    }
}
private struct LitGoldParticle: Identifiable { let id: Int; let x: CGFloat; let size: CGFloat; let duration: Double }
private struct LitGoldView: View {
    let p: LitGoldParticle; @State private var y: CGFloat = 12; @State private var opacity: Double = 0; @State private var rotation: Double = 0
    var body: some View {
        ZStack {
            Ellipse().fill(LinearGradient(colors:[Color(red:1,green:0.97,blue:0.45),Color(red:0.88,green:0.62,blue:0)], startPoint:.topLeading, endPoint:.bottomTrailing))
                .frame(width: p.size*0.65, height: p.size)
            Ellipse().strokeBorder(Color(red:0.55,green:0.32,blue:0).opacity(0.5), lineWidth: 0.7).frame(width: p.size*0.65, height: p.size)
        }
        .rotationEffect(.degrees(rotation)).opacity(opacity).offset(x: p.x, y: y)
        .onAppear {
            withAnimation(.easeOut(duration: 0.08)) { opacity = 0.9 }
            withAnimation(.easeOut(duration: p.duration)) { y = CGFloat.random(in: -38 ... -18); rotation = Double.random(in: 180...540) }
            withAnimation(.easeIn(duration: 0.22).delay(p.duration*0.68)) { opacity = 0 }
        }
    }
}

// Ice: blizzard crystal particles + rotating snowflake
private struct IceTileOverlay: View {
    @State private var particles: [LitIceParticle] = []
    @State private var activeIDs: Set<Int> = []
    @State private var snowAngle: Double = 0
    @State private var isRunning = false
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Snowflake
            ZStack {
                ForEach(0..<6) { i in
                    Capsule().fill(Color.white.opacity(0.7)).frame(width: 14, height: 1.2).offset(x: 7).rotationEffect(.degrees(Double(i)*60 + snowAngle))
                }
                Circle().fill(Color.white.opacity(0.9)).frame(width: 3.5, height: 3.5)
            }
            ForEach(particles.filter { activeIDs.contains($0.id) }) { p in LitIceView(p: p) }
        }
        .onAppear { isRunning = true; withAnimation(.linear(duration: 7).repeatForever(autoreverses: false)) { snowAngle = 360 }
            for i in 0..<6 { DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)*0.07) { spawn() } } }
        .onDisappear { isRunning = false }
        .onReceive(timer) { _ in if isRunning { spawn() } }
    }
    private func spawn() {
        let id = Int.random(in: 0..<1_000_000); let sx = CGFloat.random(in: -34...34); let sy = CGFloat.random(in: -34...34)
        let drift = CGFloat.random(in: 8...18)
        let p = LitIceParticle(id: id, sx: sx, sy: sy, ex: sx+drift, ey: sy+drift, size: CGFloat.random(in: 1.5...4), duration: Double.random(in: 0.5...0.9))
        particles.append(p); activeIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + p.duration + 0.1) { activeIDs.remove(id); particles.removeAll { $0.id == id } }
    }
}
private struct LitIceParticle: Identifiable { let id: Int; let sx: CGFloat; let sy: CGFloat; let ex: CGFloat; let ey: CGFloat; let size: CGFloat; let duration: Double }
private struct LitIceView: View {
    let p: LitIceParticle; @State private var x: CGFloat = 0; @State private var y: CGFloat = 0; @State private var opacity: Double = 0
    var body: some View {
        Circle().fill(Color.white.opacity(0.85)).frame(width: p.size, height: p.size).opacity(opacity).offset(x: x, y: y)
        .onAppear {
            x = p.sx; y = p.sy
            withAnimation(.easeIn(duration: 0.1)) { opacity = 0.9 }
            withAnimation(.linear(duration: p.duration)) { x = p.ex; y = p.ey }
            withAnimation(.easeOut(duration: 0.25).delay(p.duration*0.72)) { opacity = 0 }
        }
    }
}

// Pirate: cannonball streaks + storm flash
private struct PirateTileOverlay: View {
    @State private var cannonballs: [LitCannonball] = []
    @State private var activeIDs: Set<Int> = []
    @State private var stormFlash: Double = 0
    @State private var isRunning = false
    private let cbTimer    = Timer.publish(every: 0.5,  on: .main, in: .common).autoconnect()
    private let stormTimer = Timer.publish(every: 1.7,  on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18).fill(Color(red:0.7,green:0.4,blue:1).opacity(stormFlash)).blendMode(.screen)
            ForEach(cannonballs.filter { activeIDs.contains($0.id) }) { cb in LitCannonballView(cb: cb) }
        }
        .onAppear { isRunning = true; triggerStorm(); for i in 0..<2 { DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)*0.3) { spawn() } } }
        .onDisappear { isRunning = false }
        .onReceive(cbTimer)    { _ in if isRunning { spawn() } }
        .onReceive(stormTimer) { _ in if isRunning { triggerStorm() } }
    }
    private func triggerStorm() {
        stormFlash = 0
        withAnimation(.easeOut(duration: 0.04)) { stormFlash = 0.35 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { withAnimation(.easeOut(duration: 0.06)) { stormFlash = 0.04 } }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) { withAnimation(.easeOut(duration: 0.04)) { stormFlash = 0.25 } }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) { withAnimation(.easeIn(duration: 0.25)) { stormFlash = 0 } }
    }
    private func spawn() {
        let id = Int.random(in: 0..<1_000_000); let angle = Double.random(in: 0..<360); let rad = angle * .pi / 180
        let cb = LitCannonball(id: id, sx: cos(rad)*38, sy: sin(rad)*38, angle: angle+180, speed: Double.random(in: 0.3...0.5))
        cannonballs.append(cb); activeIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + cb.speed + 0.1) { activeIDs.remove(id); cannonballs.removeAll { $0.id == id } }
    }
}
private struct LitCannonball: Identifiable { let id: Int; let sx: CGFloat; let sy: CGFloat; let angle: Double; let speed: Double }
private struct LitCannonballView: View {
    let cb: LitCannonball; @State private var x: CGFloat = 0; @State private var y: CGFloat = 0; @State private var opacity: Double = 0
    var body: some View {
        let rad = cb.angle * Double.pi / 180
        ZStack {
            Capsule().fill(Color(red:0.5,green:0.4,blue:0.55).opacity(0.4)).frame(width: 16, height: 2).rotationEffect(.degrees(cb.angle+90)).blur(radius: 1)
                .offset(x: x - CGFloat(cos(rad)) * 8, y: y - CGFloat(sin(rad)) * 8)
            Circle().fill(RadialGradient(colors:[Color(red:0.55,green:0.55,blue:0.6),Color(red:0.2,green:0.2,blue:0.22)], center:.init(x:0.35,y:0.3), startRadius:0, endRadius:4))
                .frame(width: 7, height: 7).offset(x: x, y: y)
        }
        .opacity(opacity)
        .onAppear {
            x = cb.sx; y = cb.sy
            withAnimation(.easeIn(duration: 0.08)) { opacity = 1 }
            withAnimation(.linear(duration: cb.speed)) { x = cb.sx + CGFloat(cos(rad)) * 76; y = cb.sy + CGFloat(sin(rad)) * 76 }
            withAnimation(.easeIn(duration: 0.2).delay(cb.speed*0.75)) { opacity = 0 }
        }
    }
}

#Preview {
    LightItUpView()
        .environmentObject(ScoreStore())
        .environmentObject(CoinStore())
}
