//
//  HelpView.swift
//  ios-project

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

// MARK: - Help Background

private struct HelpBackground: View {
    @State private var drift = false

    var body: some View {
        ZStack {
            T.bg.ignoresSafeArea()

            LinearGradient(
                colors: [T.accent.opacity(0.12), T.accent.opacity(0.03), Color.clear],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.45)
            )
            .ignoresSafeArea()

            Ellipse()
                .fill(RadialGradient(
                    colors: [Color(red: 0.38, green: 0.16, blue: 0.78).opacity(0.30), Color.clear],
                    center: .center, startRadius: 0, endRadius: 180
                ))
                .frame(width: 280, height: 250)
                .blur(radius: 70)
                .offset(x: drift ? 140 : 120, y: drift ? -380 : -400)
                .animation(.easeInOut(duration: 10).repeatForever(autoreverses: true), value: drift)

            Ellipse()
                .fill(RadialGradient(
                    colors: [T.highlight.opacity(0.16), Color.clear],
                    center: .center, startRadius: 0, endRadius: 150
                ))
                .frame(width: 240, height: 220)
                .blur(radius: 65)
                .offset(x: drift ? -120 : -100, y: drift ? 420 : 440)
                .animation(.easeInOut(duration: 12).repeatForever(autoreverses: true), value: drift)
        }
        .onAppear { drift = true }
    }
}

// MARK: - Game enum

enum HelpGame {
    case tapFrenzy
    case lightItUp
}

// MARK: - Root entry point

struct HelpView: View {
    let game: HelpGame
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HelpBackground()


            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    switch game {
                    case .tapFrenzy:  TapFrenzyHelp()
                    case .lightItUp:  LightItUpHelp()
                    }
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 22)
                .padding(.top, 24)
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
    }
}

// MARK: - Shared helpers

private struct HelpHeader: View {
    let icon: String
    let title: String
    let subtitle: String
    let accent: Color

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.12))
                    .frame(width: 64, height: 64)
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(accent)
            }
            Text(title)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .tracking(3)
            Text(subtitle)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(T.secondary)
                .tracking(2)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 28)
    }
}

private struct HelpSection: View {
    let title: String
    let accent: Color
    let content: AnyView

    init(_ title: String, accent: Color, @ViewBuilder content: () -> some View) {
        self.title   = title
        self.accent  = accent
        self.content = AnyView(content())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(accent)
                    .frame(width: 3, height: 14)
                    .clipShape(Capsule())
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
                    .tracking(3)
            }

            content
        }
        .padding(.bottom, 24)
    }
}

private struct HelpRow: View {
    let icon: String
    let iconColor: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 24)
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(T.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(T.card)
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(iconColor.opacity(0.22), lineWidth: 1))
        )
    }
}

// MARK: - Animated demo helpers

/// A pulsing tap-button miniature that shrinks and bounces to mimic a real press
private struct MiniTapButton: View {
    let color: Color
    let label: String
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.18))
                .frame(width: 58, height: 58)
                .blur(radius: 6)
            Circle()
                .fill(LinearGradient(colors: [color, color.opacity(0.7)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 50, height: 50)
                .shadow(color: color.opacity(0.5), radius: 8)
            Text(label)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
        }
        .scaleEffect(scale)
        .onAppear { loopTap() }
    }

    private func loopTap() {
        withAnimation(.spring(response: 0.14, dampingFraction: 0.4)) { scale = 0.82 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.5)) { scale = 1.0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { loopTap() }
    }
}

/// Ripple ring that expands and fades from a center point
private struct DemoRipple: View {
    let color: Color
    let delay: Double
    @State private var scale: CGFloat = 0.2
    @State private var opacity: Double = 0

    var body: some View {
        Circle()
            .strokeBorder(color, lineWidth: 1.5)
            .frame(width: 60, height: 60)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { loop() }
            }
    }

    private func loop() {
        scale = 0.2; opacity = 0
        withAnimation(.easeOut(duration: 0.1)) { opacity = 0.9 }
        withAnimation(.easeOut(duration: 1.1)) { scale = 2.2 }
        withAnimation(.easeIn(duration: 0.8).delay(0.3)) { opacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { loop() }
    }
}

/// Finger icon that taps downward
private struct TapPointer: View {
    let color: Color
    @State private var offsetY: CGFloat = 0
    @State private var opacity: Double = 0.9

    var body: some View {
        Image(systemName: "hand.point.up.left.fill")
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(color)
            .rotationEffect(.degrees(180))
            .offset(y: offsetY)
            .opacity(opacity)
            .onAppear { loopTap() }
    }

    private func loopTap() {
        withAnimation(.easeIn(duration: 0.1)) { offsetY = 6; opacity = 1.0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { offsetY = 0; opacity = 0.9 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { loopTap() }
    }
}

/// Glowing tile that lights up and dims
private struct DemoTile: View {
    let color: Color
    let delay: Double
    @State private var lit: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(lit ? AnyShapeStyle(LinearGradient(
                colors: [color.opacity(0.9), color.opacity(0.6)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
                      : AnyShapeStyle(T.card))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .strokeBorder(lit ? color.opacity(0.8) : T.surface, lineWidth: 1.5))
            .shadow(color: lit ? color.opacity(0.5) : .clear, radius: lit ? 10 : 0)
            .scaleEffect(lit ? 1.06 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.6), value: lit)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { loopLight() }
            }
    }

    private func loopLight() {
        lit = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { lit = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { loopLight() }
    }
}

// MARK: - Animated demo scenes

/// Shows the shrinking button behaviour — full width, ripples clipped
private struct ShrinkingButtonDemo: View {
    var body: some View {
        // Use GeometryReader so the button zone is always full container width
        GeometryReader { geo in
            HStack(spacing: 0) {

                // Button + ripples — takes most of the width, clips overflow
                VStack(spacing: 8) {
                    ZStack {
                        DemoRipple(color: Color(red: 1, green: 0.3, blue: 0.3), delay: 0)
                        DemoRipple(color: Color(red: 1, green: 0.3, blue: 0.3), delay: 0.65)
                        MiniTapButton(color: Color(red: 0.95, green: 0.2, blue: 0.2), label: "TAP")
                    }
                    // Fixed square so ripples expand inside a known boundary
                    .frame(width: 110, height: 110)
                    .clipped()

                    Text("SHRINKS OVER TIME")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundColor(T.secondary.opacity(0.65))
                        .tracking(1)
                }
                .frame(maxWidth: .infinity)

                // Divider
                Rectangle()
                    .fill(T.card)
                    .frame(width: 1, height: 80)

                // Timer bar + label
                VStack(alignment: .leading, spacing: 8) {
                    Text("10s")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(T.secondary)

                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(T.card)
                            .frame(height: 5)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(red: 1, green: 0.3, blue: 0.3))
                            .frame(width: 70, height: 5)
                    }

                    Text("TIME LEFT")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundColor(T.secondary.opacity(0.55))
                        .tracking(1)

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(T.secondary.opacity(0.55))
                        Text("tap fast!")
                            .font(.system(size: 10, design: .rounded))
                            .foregroundColor(T.secondary.opacity(0.55))
                    }
                }
                .padding(.leading, 16)
                .frame(maxWidth: .infinity)
            }
            .frame(width: geo.size.width)
        }
        .frame(height: 148)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(T.surface))
    }
}

/// Shows 3 trap button colours with their effects
private struct TrapColorDemo: View {
    private let traps: [(Color, String, String, String)] = [
        (Color(red: 0.95, green: 0.2, blue: 0.2),  "TAP",  "RED",   "+1 point"),
        (Color(red: 0.1,  green: 0.85, blue: 0.4), "BONUS","GREEN", "+2 points"),
        (Color(red: 0.38, green: 0.38, blue: 0.42),"TRAP", "GREY",  "−1 point"),
    ]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(traps, id: \.1) { color, label, name, effect in
                VStack(spacing: 8) {
                    MiniTapButton(color: color, label: label)
                    Text(name)
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(color)
                        .tracking(1)
                    Text(effect)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(T.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(T.surface))
    }
}

/// Streak multiplier ladder demo
private struct StreakLadderDemo: View {
    private let steps: [(Int, String, Color)] = [
        (1, "×1",  .white),
        (2, "×2",  Color(red: 0.3, green: 0.8, blue: 1.0)),
        (3, "×3",  Color(red: 0.3, green: 1.0, blue: 0.5)),
        (4, "×4",  Color(red: 1.0, green: 0.8, blue: 0.1)),
    ]
    @State private var active = 0

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(steps, id: \.0) { _, label, color in
                    let idx = steps.firstIndex(where: { $0.1 == label }) ?? 0
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(idx == active ? color.opacity(0.2) : T.surface)
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(idx == active ? color.opacity(0.7) : T.card,
                                              lineWidth: 1.5))
                        Text(label)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundColor(idx == active ? color : T.secondary.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .shadow(color: idx == active ? color.opacity(0.4) : .clear, radius: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.65), value: active)
                }
            }
            Text("tap within 0.5s to keep your streak alive")
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(T.secondary.opacity(0.65))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(T.surface))
        .onAppear { cycleStreak() }
    }

    private func cycleStreak() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            active = (active + 1) % steps.count
            cycleStreak()
        }
    }
}

/// Light It Up grid demo — tiles light up and a tap pointer follows
private struct GridTapDemo: View {
    private let color = Color(red: 0.25, green: 0.55, blue: 1.0)
    private let cols  = 3
    private let rows  = 2
    @State private var litIndex: Int    = 0
    @State private var pointerPos: CGPoint = .zero

    // Fixed tile size so the grid has a known height
    private let tileSize: CGFloat = 56
    private let gap: CGFloat      = 10

    var gridHeight: CGFloat {
        CGFloat(rows) * tileSize + CGFloat(rows - 1) * gap
    }

    var body: some View {
        VStack(spacing: 14) {
            // Grid + floating pointer — ZStack only around the grid
            ZStack {
                VStack(spacing: gap) {
                    ForEach(0..<rows, id: \.self) { r in
                        HStack(spacing: gap) {
                            ForEach(0..<cols, id: \.self) { c in
                                DemoTile(color: color, delay: Double(r * cols + c) * 0.22)
                                    .frame(width: tileSize, height: tileSize)
                            }
                        }
                    }
                }

                TapPointer(color: .white)
                    .offset(x: pointerPos.x, y: pointerPos.y)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: pointerPos)
            }
            .frame(height: gridHeight)
            .onAppear { movePointer() }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(T.surface))
    }

    private func movePointer() {
        let idx = litIndex % (cols * rows)
        let col = CGFloat(idx % cols)
        let row = CGFloat(idx / cols)

        // Centre of each tile relative to grid centre
        let gridW = CGFloat(cols) * tileSize + CGFloat(cols - 1) * gap
        let gridH = CGFloat(rows) * tileSize + CGFloat(rows - 1) * gap
        let cx = col * (tileSize + gap) + tileSize / 2 - gridW / 2
        let cy = row * (tileSize + gap) + tileSize / 2 - gridH / 2

        pointerPos = CGPoint(x: cx, y: cy)
        litIndex  += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { movePointer() }
    }
}

/// Lives heart row animation — one fades when missed
private struct LivesDemo: View {
    @State private var lives = 3
    private let heartColor = Color(red: 1, green: 0.25, blue: 0.35)

    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < lives ? "heart.fill" : "heart")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(i < lives ? heartColor : T.surface)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: lives)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Miss a tile → lose a ♥")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(T.secondary)
                Text("Tap wrong tile → lose a ♥")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(T.secondary)
                Text("0 lives = game over")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(T.secondary.opacity(0.65))
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(T.surface))
        .onAppear { cycleLives() }
    }

    private func cycleLives() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if lives > 0 { lives -= 1 } else { lives = 3 }
            cycleLives()
        }
    }
}

// MARK: - Tap Frenzy Help

private struct TapFrenzyHelp: View {
    private let accent = T.accent
    private let green  = Color(red: 0.1,  green: 0.85, blue: 0.4)
    private let blue   = Color(red: 0.3,  green: 0.8,  blue: 1.0)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            HelpHeader(
                icon: "hand.tap.fill",
                title: "TAP FRENZY",
                subtitle: "TAP FAST · AVOID TRAPS · BEAT THE CLOCK",
                accent: accent
            )

            HelpSection("THE GOAL", accent: accent) {
                HelpRow(icon: "target",
                        iconColor: accent,
                        text: "Tap the button as many times as you can in 10 seconds. The button shrinks as time runs out — tap before it disappears!")
            }

            HelpSection("HOW IT WORKS", accent: accent) {
                VStack(spacing: 10) {
                    ShrinkingButtonDemo()
                    HelpRow(icon: "clock.fill",
                            iconColor: T.highlight,
                            text: "You have 10 seconds. The button gets smaller every second, so get your taps in early.")
                }
            }

            HelpSection("BUTTON COLOURS", accent: accent) {
                VStack(spacing: 10) {
                    TrapColorDemo()
                    HelpRow(icon: "exclamationmark.triangle.fill",
                            iconColor: T.highlight,
                            text: "The button randomly switches colour. A label flashes briefly to warn you — react fast!")
                }
            }

            HelpSection("GAME MODES", accent: accent) {
                VStack(spacing: 10) {
                    HelpRow(icon: "circle.fill",
                            iconColor: accent,
                            text: "NORMAL — tap as many times as possible. Simple and fast.")
                    HelpRow(icon: "flame.fill",
                            iconColor: blue,
                            text: "STREAK — tap within 0.5s of your last tap to keep a streak alive. Longer streaks unlock score multipliers up to ×4.")
                    VStack(spacing: 8) {
                        StreakLadderDemo()
                    }
                    HelpRow(icon: "figure.run",
                            iconColor: T.highlight,
                            text: "GHOST — race against a replay of your previous run. A progress bar shows if you're ahead or behind.")
                }
            }

            HelpSection("TIPS", accent: accent) {
                TipsBlock(tips: [
                    "Tap at the very start when the button is largest — you'll rack up the most points quickly.",
                    "In Streak mode, keep a steady rhythm. One long pause resets everything.",
                    "Green buttons give +2 — always tap them. Grey buttons cost you −1, so you can choose to skip."
                ])
            }
        }
    }
}

// MARK: - Level Row (used in Light It Up help)

private struct LevelRow: View {
    let number: String
    let accent: Color
    let time: String
    let tiles: String
    let window: String
    let note: String

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Badge
            ZStack {
                Circle()
                    .fill(accent.opacity(0.18))
                    .frame(width: 36, height: 36)
                Text(number)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(accent)
            }

            // Info columns — fixed widths keep all four rows aligned
            HStack(spacing: 0) {
                Text(time)
                    .frame(width: 80, alignment: .leading)
                Text(tiles)
                    .frame(width: 60, alignment: .leading)
                Text(window)
                    .frame(width: 76, alignment: .leading)
            }
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(T.secondary)

            Spacer(minLength: 0)

            Text(note)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(accent.opacity(0.75))
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

private var levelDivider: some View {
    Rectangle()
        .fill(T.card)
        .frame(height: 1)
        .padding(.horizontal, 14)
}

/// Single-container tip list with dividers — keeps all rows visually aligned
private struct TipsBlock: View {
    let tips: [String]
    private let yellow = Color(red: 1, green: 0.85, blue: 0.2)

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(yellow)
                        .frame(width: 20)
                        .padding(.top, 2)
                    Text(tip)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(T.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

                if index < tips.count - 1 {
                    Rectangle()
                        .fill(T.card)
                        .frame(height: 1)
                        .padding(.horizontal, 14)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(T.surface)
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(T.card, lineWidth: 1))
        )
    }
}

// MARK: - Light It Up Help

private struct LightItUpHelp: View {
    private let cyan   = Color(red: 0.2,  green: 0.75, blue: 1.0)
    private let orange = Color(red: 1.0,  green: 0.55, blue: 0.1)
    private let red    = Color(red: 1.0,  green: 0.25, blue: 0.25)
    private let blue   = Color(red: 0.25, green: 0.55, blue: 1.0)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            HelpHeader(
                icon: "bolt.fill",
                title: "LIGHT IT UP",
                subtitle: "TAP THE GLOW · MOVE FAST · SURVIVE 60s",
                accent: T.highlight
            )

            HelpSection("THE GOAL", accent: T.highlight) {
                HelpRow(icon: "bolt.fill",
                        iconColor: T.highlight,
                        text: "Tiles randomly light up on a grid. Tap a glowing tile before it goes dark to score a point. Miss it and you lose a life.")
            }

            HelpSection("HOW IT WORKS", accent: T.highlight) {
                VStack(spacing: 10) {
                    GridTapDemo()
                    HelpRow(icon: "square.grid.3x3.fill",
                            iconColor: T.accent,
                            text: "A random tile lights up. You have a short window to tap it. If time runs out, that tile goes dark and you lose a life.")
                    HelpRow(icon: "hand.tap.fill",
                            iconColor: T.highlight,
                            text: "Tap the glowing tile to score +1. Tapping a dark tile is a wrong tap — also costs a life.")
                }
            }

            HelpSection("LIVES", accent: red) {
                VStack(spacing: 10) {
                    LivesDemo()
                }
            }

            HelpSection("LEVELS", accent: T.accent) {
                VStack(spacing: 0) {
                    LevelRow(number: "1", accent: blue,
                             time: "0 – 15s", tiles: "3 tiles",
                             window: "1.5s window", note: "Easy warm-up")
                    levelDivider
                    LevelRow(number: "2", accent: cyan,
                             time: "15 – 30s", tiles: "4 tiles",
                             window: "1.2s window", note: "Grid grows")
                    levelDivider
                    LevelRow(number: "3", accent: orange,
                             time: "30 – 45s", tiles: "6 tiles",
                             window: "1.0s window", note: "Multiple at once")
                    levelDivider
                    LevelRow(number: "4", accent: red,
                             time: "45 – 60s", tiles: "9 tiles",
                             window: "0.8s window", note: "Two lit simultaneously")
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(T.surface)
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(T.card, lineWidth: 1))
                )
            }

            HelpSection("TIPS", accent: T.highlight) {
                TipsBlock(tips: [
                    "Keep your thumb hovering near the centre of the grid — tiles can appear anywhere.",
                    "Don't panic-tap dark tiles. A wrong tap costs you the same as a miss.",
                    "In Level 4 two tiles light at once — tap the one closer to your thumb first, then quickly shift."
                ])
            }
        }
    }
}

#Preview {
    HelpView(game: .tapFrenzy)
}
