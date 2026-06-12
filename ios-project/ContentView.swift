//
//  ContentView.swift
//  ios-project
//
//  Created by Mufli Mohideen on 2026-06-10.
//

import SwiftUI

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

struct ContentView: View {
    @State private var score: Int = 0
    @State private var timeRemaining: Int = 10
    @State private var isGameActive: Bool = false
    @State private var gameTimer: Timer?
    @State private var trapTimer: Timer?
    @State private var buttonScale: CGFloat = 1.0
    @State private var trapColor: TrapColor = .red
    @State private var showTrapLabel: Bool = false
    @State private var highScore: Int = 0
    @State private var isNewHighScore: Bool = false

    // Shrinks from 230 at 10s down to 72 at 0s
    var buttonSize: CGFloat {
        let fraction = CGFloat(timeRemaining) / 10.0
        return 72 + fraction * 158
    }

    var timerColor: Color {
        if timeRemaining <= 3 { return Color(red: 1.0, green: 0.25, blue: 0.25) }
        if timeRemaining <= 6 { return Color(red: 1.0, green: 0.65, blue: 0.1) }
        return .white
    }

    var body: some View {
        ZStack {
            // Deep dark gradient background
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.06, blue: 0.10), Color(red: 0.04, green: 0.04, blue: 0.08)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            if isGameActive || timeRemaining > 0 {
                gameView
                    .transition(.opacity)
            } else {
                gameOverView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: isGameActive)
        .onAppear { startGame() }
        .onDisappear { stopTimers() }
    }

    // MARK: - Game View

    var gameView: some View {
        VStack(spacing: 0) {

            // ── Score card ──
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
            }
            .padding(.vertical, 22)
            .frame(width: 260)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .strokeBorder(trapColor.accentColor.opacity(0.25), lineWidth: 1.5)
                    )
            )
            .padding(.top, 64)

            Spacer()

            // ── Trap hint pill ──
            ZStack {
                if showTrapLabel, let label = trapColor.bonusText {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(trapColor.accentColor)
                            .frame(width: 8, height: 8)
                        Text(label)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(trapColor.accentColor)
                        Circle()
                            .fill(trapColor.accentColor)
                            .frame(width: 8, height: 8)
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

            // ── TAP button ──
            Button(action: buttonTapped) {
                ZStack {
                    // Outer glow ring
                    Circle()
                        .fill(trapColor.glowColor.opacity(0.18))
                        .frame(width: buttonSize + 28, height: buttonSize + 28)
                        .blur(radius: 12)

                    // Main fill
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: trapColor.colors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: buttonSize, height: buttonSize)
                        .shadow(color: trapColor.glowColor, radius: 22, x: 0, y: 8)

                    // Specular highlight
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

                    // Border ring
                    Circle()
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 2)
                        .frame(width: buttonSize, height: buttonSize)

                    // Label — hide when tiny
                    if buttonSize > 110 {
                        VStack(spacing: 2) {
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
            .buttonStyle(.plain)
            .scaleEffect(buttonScale)
            .animation(.spring(response: 0.28, dampingFraction: 0.5), value: buttonScale)
            .animation(.easeInOut(duration: 0.5), value: buttonSize)
            .animation(.easeInOut(duration: 0.4), value: trapColor.glowColor)
            .disabled(!isGameActive)

            Spacer()

            // ── Timer bar + display ──
            VStack(spacing: 10) {
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.08))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [timerColor.opacity(0.9), timerColor],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
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

    // MARK: - Game Over View

    var gameOverView: some View {
        VStack(spacing: 0) {
            Spacer()

            // Trophy / heading
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

            // Score
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

                Text("TAPS")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(5)
            }

            // High score row
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.yellow.opacity(0.7))
                Text("BEST  \(highScore)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.45))
                    .tracking(3)
            }
            .padding(.top, 16)
            .padding(.bottom, 44)

            // Play again
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

    func buttonTapped() {
        guard isGameActive else { return }

        switch trapColor {
        case .green: score += 2
        case .grey:  score = max(0, score - 1)
        case .red:   score += 1
        }

        withAnimation(.spring(response: 0.15, dampingFraction: 0.4)) {
            buttonScale = 0.88
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                buttonScale = 1.0
            }
        }
    }

    func startGame() {
        score = 0
        timeRemaining = 10
        trapColor = .red
        showTrapLabel = false
        isNewHighScore = false
        isGameActive = true
        startGameTimer()
        startTrapTimer()
    }

    func startGameTimer() {
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimers()
                isGameActive = false
                if score > highScore {
                    highScore = score
                    isNewHighScore = true
                }
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
    }
}

#Preview {
    ContentView()
}
