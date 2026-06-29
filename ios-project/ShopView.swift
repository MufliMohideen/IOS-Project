//
//  ShopView.swift
//  ios-project
//

import SwiftUI
import Combine

// MARK: - Gold coin icon (reusable, replaces 🪙 everywhere)

struct GoldCoinIcon: View {
    var size: CGFloat = 14

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [
                        Color(red: 1.0, green: 0.97, blue: 0.45),
                        Color(red: 1.0, green: 0.78, blue: 0.0),
                        Color(red: 0.82, green: 0.52, blue: 0.0),
                    ],
                    center: .init(x: 0.38, y: 0.3), startRadius: 0, endRadius: size * 0.5
                ))
                .frame(width: size, height: size)
                .shadow(color: Color(red: 1.0, green: 0.75, blue: 0.0).opacity(0.6), radius: size * 0.3)
            // Shine glint top-left
            Ellipse()
                .fill(Color.white.opacity(0.55))
                .frame(width: size * 0.28, height: size * 0.18)
                .offset(x: -size * 0.14, y: -size * 0.2)
            // Rim
            Circle()
                .strokeBorder(Color(red: 0.65, green: 0.38, blue: 0.0).opacity(0.5), lineWidth: size * 0.06)
                .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Theme

private enum T {
    static let bg        = Color(red: 0.067, green: 0.067, blue: 0.067)
    static let surface   = Color(red: 0.11,  green: 0.11,  blue: 0.118)
    static let card      = Color(red: 0.173, green: 0.173, blue: 0.18)
    static let accent    = Color(red: 0.545, green: 0.361, blue: 0.965)
    static let highlight = Color(red: 0.655, green: 0.545, blue: 0.98)
    static let secondary = Color(red: 0.69,  green: 0.69,  blue: 0.69)
}

// MARK: - Per-skin animated previews

// Fire: full burning effect with layered flames + ember particles
private struct FlameParticle: Identifiable {
    let id: Int
    let xStart: CGFloat
    let xDrift: CGFloat    // how much it sways sideways as it rises
    let size: CGFloat
    let duration: Double
    let delay: Double
    let isEmber: Bool      // embers are tiny bright dots, flames are soft blobs
}

private struct FireButtonPreview: View {
    @State private var particles: [FlameParticle] = []
    @State private var activeIDs: Set<Int> = []
    @State private var glowRadius: CGFloat = 12
    @State private var innerFlame: Bool = false
    @State private var isRunning = false

    // Repeating timers at different rates for dense flame
    private let fastTimer   = Timer.publish(every: 0.09, on: .main, in: .common).autoconnect()
    private let emberTimer  = Timer.publish(every: 0.16, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Dark burned core
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.95, green: 0.35, blue: 0.0),
                            Color(red: 0.7,  green: 0.08, blue: 0.0),
                            Color(red: 0.4,  green: 0.02, blue: 0.0),
                        ],
                        center: .center, startRadius: 0, endRadius: 36
                    )
                )
                .frame(width: 70, height: 70)

            // Outer heat glow — breathes
            Circle()
                .fill(Color(red: 1.0, green: 0.3, blue: 0.0).opacity(0.35))
                .frame(width: 70, height: 70)
                .blur(radius: glowRadius)
                .animation(.easeInOut(duration: 0.18).repeatForever(autoreverses: true), value: glowRadius)

            // Flame & ember particles
            ForEach(particles.filter { activeIDs.contains($0.id) }) { p in
                FlameParticleView(particle: p)
            }

            // Inner hot white-yellow core shimmer
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(innerFlame ? 0.45 : 0.15), Color.clear],
                        center: .center, startRadius: 0, endRadius: 18
                    )
                )
                .frame(width: 36, height: 36)
                .animation(.easeInOut(duration: 0.12).repeatForever(autoreverses: true), value: innerFlame)

            // Subtle char ring at button edge
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.55, blue: 0.0).opacity(0.8), Color.black.opacity(0.5)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 2.5
                )
                .frame(width: 70, height: 70)
        }
        .frame(width: 70, height: 70)
        .clipShape(Circle())
        .shadow(color: Color(red: 1.0, green: 0.35, blue: 0.0).opacity(0.8), radius: 16)
        .onAppear {
            isRunning = true
            // Kick off glow flicker immediately
            glowRadius = 20
            innerFlame = true
            // Seed initial burst of particles
            for i in 0..<8 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                    spawnFlame()
                }
            }
        }
        .onDisappear { isRunning = false }
        .onReceive(fastTimer)  { _ in if isRunning { spawnFlame() } }
        .onReceive(emberTimer) { _ in if isRunning { spawnEmber() } }
    }

    private func spawnFlame() {
        let id = Int.random(in: 0..<1_000_000)
        let p = FlameParticle(
            id: id,
            xStart: CGFloat.random(in: -22...22),
            xDrift: CGFloat.random(in: -14...14),
            size: CGFloat.random(in: 14...28),
            duration: Double.random(in: 0.45...0.75),
            delay: 0,
            isEmber: false
        )
        particles.append(p)
        activeIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + p.duration + 0.1) {
            activeIDs.remove(id)
            particles.removeAll { $0.id == id }
        }
    }

    private func spawnEmber() {
        let id = Int.random(in: 0..<1_000_000)
        let p = FlameParticle(
            id: id,
            xStart: CGFloat.random(in: -18...18),
            xDrift: CGFloat.random(in: -20...20),
            size: CGFloat.random(in: 3...6),
            duration: Double.random(in: 0.6...1.1),
            delay: 0,
            isEmber: true
        )
        particles.append(p)
        activeIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + p.duration + 0.15) {
            activeIDs.remove(id)
            particles.removeAll { $0.id == id }
        }
    }
}

private struct FlameParticleView: View {
    let particle: FlameParticle
    @State private var y: CGFloat = 0
    @State private var x: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.3

    var body: some View {
        Group {
            if particle.isEmber {
                // Ember: tiny bright glowing dot
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white, Color.yellow, Color(red: 1.0, green: 0.5, blue: 0.0).opacity(0)],
                            center: .center, startRadius: 0, endRadius: particle.size / 2
                        )
                    )
                    .frame(width: particle.size, height: particle.size)
                    .opacity(opacity)
                    .scaleEffect(scale)
                    .offset(x: x, y: y)
            } else {
                // Flame tongue: soft oval blob, yellow at core → orange → transparent
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.9),
                                Color(red: 1.0, green: 0.85, blue: 0.0).opacity(0.8),
                                Color(red: 1.0, green: 0.4,  blue: 0.0).opacity(0.5),
                                Color(red: 0.9, green: 0.1,  blue: 0.0).opacity(0.0),
                            ],
                            center: .center, startRadius: 0, endRadius: particle.size / 2
                        )
                    )
                    .frame(width: particle.size * 0.65, height: particle.size)
                    .opacity(opacity)
                    .scaleEffect(scale)
                    .offset(x: x, y: y)
                    .blur(radius: 2)
            }
        }
        .onAppear {
            x = particle.xStart
            y = 10
            // Fade in fast
            withAnimation(.easeOut(duration: 0.08)) {
                opacity = particle.isEmber ? 1.0 : 0.85
                scale   = 1.0
            }
            // Rise and drift sideways, fade out
            withAnimation(.easeOut(duration: particle.duration)) {
                y = particle.isEmber ? CGFloat.random(in: -55 ... -38) : CGFloat.random(in: -44 ... -22)
                x = particle.xStart + particle.xDrift
                opacity = 0
                scale   = particle.isEmber ? 0.5 : 0.3
            }
        }
    }
}

// MARK: - Galaxy: procedural deep-space scene — no emoji

private struct WarpStar: Identifiable {
    let id: Int
    let angle: Double
    let speed: Double
    let startRadius: CGFloat   // starts close to center, zooms out
    let size: CGFloat
    let color: Color
}

private struct GalaxyButtonPreview: View {
    @State private var warpStars: [WarpStar] = []
    @State private var activeWarpIDs: Set<Int> = []
    @State private var nebulaAngle: Double = 0
    @State private var corePulse: Bool = false
    @State private var blackHoleSpin: Double = 0
    @State private var isRunning = false

    // Dense star spawn rate for warp tunnel feel
    private let warpTimer  = Timer.publish(every: 0.07, on: .main, in: .common).autoconnect()

    private let starColors: [Color] = [
        .white,
        Color(red: 0.88, green: 0.75, blue: 1.0),
        Color(red: 0.65, green: 0.45, blue: 1.0),
        Color(red: 0.55, green: 0.88, blue: 1.0),
        Color(red: 1.0,  green: 0.85, blue: 0.6),
    ]

    var body: some View {
        ZStack {
            // Deep black-space base
            Circle()
                .fill(RadialGradient(
                    colors: [
                        Color(red: 0.18, green: 0.05, blue: 0.38),
                        Color(red: 0.07, green: 0.02, blue: 0.18),
                        Color.black,
                    ],
                    center: .center, startRadius: 0, endRadius: 36
                ))
                .frame(width: 70, height: 70)
                .shadow(color: Color(red: 0.55, green: 0.2, blue: 1.0).opacity(corePulse ? 0.95 : 0.35), radius: corePulse ? 24 : 10)
                .animation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true), value: corePulse)

            // Spiral nebula arms — coloured dust lanes
            ForEach(0..<4) { i in
                Ellipse()
                    .fill(
                        AngularGradient(
                            colors: [
                                Color(red: 0.6,  green: 0.15, blue: 1.0).opacity(0.35),
                                Color(red: 0.2,  green: 0.6,  blue: 1.0).opacity(0.18),
                                Color.clear,
                            ],
                            center: .center
                        )
                    )
                    .frame(width: 58, height: 16)
                    .blur(radius: 5)
                    .rotationEffect(.degrees(nebulaAngle + Double(i) * 90))
            }

            // Warp-zoom stars
            ForEach(warpStars.filter { activeWarpIDs.contains($0.id) }) { s in
                WarpStarView(star: s)
            }

            // Black-hole accretion disk — thin bright ring that spins
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [
                            Color(red: 1.0, green: 0.8, blue: 0.3).opacity(0.9),
                            Color(red: 0.8, green: 0.3, blue: 1.0).opacity(0.6),
                            Color(red: 0.3, green: 0.7, blue: 1.0).opacity(0.7),
                            Color(red: 1.0, green: 0.8, blue: 0.3).opacity(0.9),
                        ],
                        center: .center
                    ),
                    lineWidth: 2.5
                )
                .frame(width: 22, height: 22)
                .rotationEffect(.degrees(blackHoleSpin))
                .blur(radius: 1)

            // Galactic core — layered bright nucleus, no flat emoji
            ZStack {
                // Outer diffuse glow halo
                Circle()
                    .fill(RadialGradient(
                        colors: [
                            Color(red: 0.9, green: 0.75, blue: 1.0).opacity(corePulse ? 0.55 : 0.2),
                            Color(red: 0.55, green: 0.25, blue: 1.0).opacity(0.3),
                            Color.clear,
                        ],
                        center: .center, startRadius: 0, endRadius: 18
                    ))
                    .frame(width: 36, height: 36)
                    .blur(radius: 5)
                    .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: corePulse)

                // 4 bright dust lane streaks crossing the core
                ForEach(0..<4) { i in
                    Capsule()
                        .fill(LinearGradient(
                            colors: [
                                Color.clear,
                                Color(red: 0.85, green: 0.7, blue: 1.0).opacity(corePulse ? 0.7 : 0.3),
                                Color.clear,
                            ],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: 22, height: 1.2)
                        .rotationEffect(.degrees(Double(i) * 45 + blackHoleSpin * 0.3))
                        .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: corePulse)
                }

                // Bright stellar nucleus
                Circle()
                    .fill(RadialGradient(
                        colors: [
                            Color.white,
                            Color(red: 0.95, green: 0.85, blue: 1.0),
                            Color(red: 0.7, green: 0.45, blue: 1.0).opacity(0.6),
                            Color.clear,
                        ],
                        center: .center, startRadius: 0, endRadius: 7
                    ))
                    .frame(width: 14, height: 14)
                    .scaleEffect(corePulse ? 1.15 : 0.9)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: corePulse)

                // 4-point star diffraction spike
                ForEach(0..<4) { i in
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Color.white.opacity(corePulse ? 0.95 : 0.4), Color.clear],
                            startPoint: .center, endPoint: .trailing
                        ))
                        .frame(width: 10, height: 0.9)
                        .offset(x: 5)
                        .rotationEffect(.degrees(Double(i) * 45))
                        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: corePulse)
                }
            }
        }
        .frame(width: 70, height: 70)
        .clipShape(Circle())
        .onAppear {
            isRunning = true
            corePulse = true
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false))  { nebulaAngle    = 360 }
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false))  { blackHoleSpin  = 360 }
            for i in 0..<10 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.06) { spawnWarpStar() }
            }
        }
        .onDisappear { isRunning = false }
        .onReceive(warpTimer) { _ in if isRunning { spawnWarpStar() } }
    }

    private func spawnWarpStar() {
        let id    = Int.random(in: 0..<1_000_000)
        let speed = Double.random(in: 0.35...0.75)
        let s = WarpStar(
            id: id,
            angle: Double.random(in: 0..<360),
            speed: speed,
            startRadius: CGFloat.random(in: 2...8),
            size: CGFloat.random(in: 1...3.5),
            color: starColors.randomElement()!
        )
        warpStars.append(s)
        activeWarpIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + speed + 0.1) {
            activeWarpIDs.remove(id)
            warpStars.removeAll { $0.id == id }
        }
    }
}

// Star zooms from near-centre outward, leaving a faint streak tail
private struct WarpStarView: View {
    let star: WarpStar
    @State private var progress: CGFloat = 0
    @State private var opacity: Double   = 0

    private var endRadius: CGFloat { 36 }

    var body: some View {
        ZStack {
            // Streak tail — elongated capsule behind the dot
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [star.color.opacity(0.0), star.color.opacity(0.55 * opacity)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(
                    width: max(1, (endRadius - star.startRadius) * progress * 0.55),
                    height: max(0.5, star.size * 0.45)
                )
                .offset(
                    x: (star.startRadius + (endRadius - star.startRadius) * progress * 0.72) * cos(star.angle * .pi / 180),
                    y: (star.startRadius + (endRadius - star.startRadius) * progress * 0.72) * sin(star.angle * .pi / 180)
                )
                .rotationEffect(.degrees(star.angle))

            // Leading dot
            Circle()
                .fill(RadialGradient(
                    colors: [Color.white, star.color.opacity(0.5), .clear],
                    center: .center, startRadius: 0, endRadius: star.size
                ))
                .frame(width: star.size * 2, height: star.size * 2)
                .opacity(opacity)
                .offset(
                    x: (star.startRadius + (endRadius - star.startRadius) * progress) * cos(star.angle * .pi / 180),
                    y: (star.startRadius + (endRadius - star.startRadius) * progress) * sin(star.angle * .pi / 180)
                )
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.08))             { opacity  = 1.0 }
            withAnimation(.easeIn(duration: star.speed))       { progress = 1.0 }
            withAnimation(.easeOut(duration: 0.2).delay(star.speed * 0.8)) { opacity = 0 }
        }
    }
}

// MARK: - Neon: jagged lightning bolts crackling across the surface

// A bolt is defined by a chain of random points from an origin out to the edge
private struct LightningBolt: Identifiable {
    let id: Int
    let points: [CGPoint]   // jagged zigzag path from centre outward
    let duration: Double
    let color: Color
    let width: CGFloat
}

private struct OrbitSpark: Identifiable {
    let id: Int
    let startAngle: Double   // degrees around the perimeter
    let direction: Double    // +1 or -1 for CW/CCW
    let speed: Double        // degrees per tick
    let duration: Double
}

private struct NeonButtonPreview: View {
    @State private var bolts: [LightningBolt] = []
    @State private var activeBoltIDs: Set<Int> = []
    @State private var orbitSparks: [OrbitSpark] = []
    @State private var activeOrbitIDs: Set<Int> = []
    @State private var coreFlicker: Bool = false
    @State private var outerGlow: Bool = false
    @State private var shockScale1: CGFloat = 1.0
    @State private var shockOpacity1: Double = 0.0
    @State private var shockScale2: CGFloat = 1.0
    @State private var shockOpacity2: Double = 0.0
    @State private var isRunning = false

    // Fast bolt bursts + slower shock waves + orbit sparks
    private let boltTimer  = Timer.publish(every: 0.11, on: .main, in: .common).autoconnect()
    private let shockTimer = Timer.publish(every: 0.7,  on: .main, in: .common).autoconnect()
    private let orbitTimer = Timer.publish(every: 0.45, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Dark electric base — almost black with deep cyan tint
            Circle()
                .fill(RadialGradient(
                    colors: [
                        Color(red: 0.0,  green: 0.18, blue: 0.28),
                        Color(red: 0.0,  green: 0.08, blue: 0.18),
                        Color.black,
                    ],
                    center: .center, startRadius: 0, endRadius: 36
                ))
                .frame(width: 70, height: 70)
                .shadow(color: Color.cyan.opacity(outerGlow ? 1.0 : 0.3), radius: outerGlow ? 26 : 10)
                .animation(.easeInOut(duration: 0.14).repeatForever(autoreverses: true), value: outerGlow)

            // Expanding shock rings (EMPs)
            Circle()
                .strokeBorder(Color.cyan.opacity(shockOpacity1), lineWidth: 1.8)
                .frame(width: 70 * shockScale1, height: 70 * shockScale1)

            Circle()
                .strokeBorder(Color.white.opacity(shockOpacity2), lineWidth: 1)
                .frame(width: 70 * shockScale2, height: 70 * shockScale2)

            // Orbiting electric sparks around the rim
            ForEach(orbitSparks.filter { activeOrbitIDs.contains($0.id) }) { spark in
                OrbitSparkView(spark: spark)
            }

            // Lightning bolt paths
            ForEach(bolts.filter { activeBoltIDs.contains($0.id) }) { bolt in
                LightningBoltView(bolt: bolt)
            }

            // Plasma core — white-hot centre that flickers rapidly
            ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [
                            Color.white.opacity(coreFlicker ? 1.0 : 0.3),
                            Color.cyan.opacity(coreFlicker ? 0.8 : 0.2),
                            Color.clear,
                        ],
                        center: .center, startRadius: 0, endRadius: 12
                    ))
                    .frame(width: 22, height: 22)
                    .blur(radius: 1.5)
                    .animation(.easeInOut(duration: 0.08).repeatForever(autoreverses: true), value: coreFlicker)

                // Tiny star burst at dead centre
                ForEach(0..<4) { i in
                    Rectangle()
                        .fill(Color.white.opacity(coreFlicker ? 0.9 : 0.3))
                        .frame(width: 10, height: 1.2)
                        .rotationEffect(.degrees(Double(i) * 45))
                        .animation(.easeInOut(duration: 0.09).repeatForever(autoreverses: true), value: coreFlicker)
                }
            }
        }
        .frame(width: 70, height: 70)
        .clipShape(Circle())
        .onAppear {
            isRunning = true
            outerGlow  = true
            coreFlicker = true
            emitShock()
            spawnOrbitSpark(); spawnOrbitSpark()
            for i in 0..<6 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) { spawnBolt() }
            }
        }
        .onDisappear { isRunning = false }
        .onReceive(boltTimer)  { _ in if isRunning { spawnBolt() } }
        .onReceive(shockTimer) { _ in if isRunning { emitShock() } }
        .onReceive(orbitTimer) { _ in if isRunning { spawnOrbitSpark() } }
    }

    private func spawnOrbitSpark() {
        let id  = Int.random(in: 0..<1_000_000)
        let dur = Double.random(in: 0.8...1.5)
        let sp  = OrbitSpark(
            id: id,
            startAngle: Double.random(in: 0..<360),
            direction: Bool.random() ? 1.0 : -1.0,
            speed: Double.random(in: 120...200),   // degrees per second of travel
            duration: dur
        )
        orbitSparks.append(sp)
        activeOrbitIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + dur + 0.1) {
            activeOrbitIDs.remove(id)
            orbitSparks.removeAll { $0.id == id }
        }
    }

    private func emitShock() {
        shockScale1 = 1.0; shockOpacity1 = 0.85
        shockScale2 = 1.0; shockOpacity2 = 0.55
        withAnimation(.easeOut(duration: 0.65)) { shockScale1 = 1.5;  shockOpacity1 = 0 }
        withAnimation(.easeOut(duration: 0.65).delay(0.15)) { shockScale2 = 1.38; shockOpacity2 = 0 }
    }

    private func spawnBolt() {
        let id    = Int.random(in: 0..<1_000_000)
        let angle = Double.random(in: 0..<360)
        let rad   = angle * .pi / 180

        // Build jagged zigzag: start near centre, end at edge (radius ~32)
        let segCount = Int.random(in: 3...5)
        var pts: [CGPoint] = [CGPoint(x: 0, y: 0)]
        let totalLen: CGFloat = CGFloat.random(in: 22...32)
        let segLen = totalLen / CGFloat(segCount)

        for seg in 1...segCount {
            let along     = segLen * CGFloat(seg)
            // perpendicular jag — more jag on inner segments, taper to tip
            let maxJag: CGFloat = seg == segCount ? 1 : CGFloat.random(in: 4...10)
            let jag = CGFloat.random(in: -maxJag...maxJag)
            // perpendicular direction to main angle
            let px = cos(rad + .pi / 2) * jag + cos(rad) * along
            let py = sin(rad + .pi / 2) * jag + sin(rad) * along
            pts.append(CGPoint(x: px, y: py))
        }

        // Alternate between main cyan and bright white for variety
        let useWhite = Bool.random()
        let boltColor: Color = useWhite ? .white : Color(red: 0.4, green: 1.0, blue: 1.0)
        let boltWidth: CGFloat = useWhite ? 1.0 : 1.6

        let bolt = LightningBolt(
            id: id, points: pts,
            duration: Double.random(in: 0.08...0.18),
            color: boltColor,
            width: boltWidth
        )
        bolts.append(bolt)
        activeBoltIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + bolt.duration + 0.05) {
            activeBoltIDs.remove(id)
            bolts.removeAll { $0.id == id }
        }
    }
}

private struct OrbitSparkView: View {
    let spark: OrbitSpark
    @State private var angle: Double = 0
    @State private var opacity: Double = 0

    private let orbitRadius: CGFloat = 31  // just inside the clipped edge

    var body: some View {
        ZStack {
            // Trailing arc glow behind the spark head
            ForEach(0..<5) { i in
                let trailAngle = angle - spark.direction * Double(i + 1) * 8
                let rad = trailAngle * .pi / 180
                Circle()
                    .fill(Color.cyan.opacity(opacity * Double(5 - i) / 5 * 0.5))
                    .frame(width: 3.5, height: 3.5)
                    .offset(
                        x: cos(rad) * orbitRadius,
                        y: sin(rad) * orbitRadius
                    )
            }
            // Spark head
            let rad = angle * .pi / 180
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 5, height: 5)
                    .blur(radius: 1)
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 3.5, height: 3.5)
            }
            .offset(x: cos(rad) * orbitRadius, y: sin(rad) * orbitRadius)
            .opacity(opacity)
        }
        .onAppear {
            angle = spark.startAngle
            withAnimation(.easeIn(duration: 0.1)) { opacity = 1.0 }
            withAnimation(.linear(duration: spark.duration)) {
                angle = spark.startAngle + spark.direction * spark.speed * spark.duration
            }
            withAnimation(.easeOut(duration: 0.25).delay(spark.duration * 0.75)) { opacity = 0 }
        }
    }
}

private struct LightningBoltView: View {
    let bolt: LightningBolt
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // Glow pass — thicker, blurred, lower opacity
            LightningPath(points: bolt.points)
                .stroke(bolt.color.opacity(0.45), lineWidth: bolt.width + 3)
                .blur(radius: 2.5)
                .opacity(opacity)

            // Core pass — sharp bright line
            LightningPath(points: bolt.points)
                .stroke(bolt.color, style: StrokeStyle(lineWidth: bolt.width, lineCap: .round, lineJoin: .round))
                .opacity(opacity)
        }
        .onAppear {
            // Instant on, quick fade
            opacity = 1.0
            withAnimation(.easeIn(duration: bolt.duration * 0.75).delay(bolt.duration * 0.25)) {
                opacity = 0
            }
        }
    }
}

private struct LightningPath: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard points.count > 1 else { return p }
        // Translate so (0,0) is the circle centre
        let cx = rect.midX
        let cy = rect.midY
        p.move(to: CGPoint(x: cx + points[0].x, y: cy + points[0].y))
        for pt in points.dropFirst() {
            p.addLine(to: CGPoint(x: cx + pt.x, y: cy + pt.y))
        }
        return p
    }
}

// MARK: - Gold: liquid molten surface + erupting sparks + spinning orbiting coins

private struct GoldParticle: Identifiable {
    let id: Int
    let x: CGFloat
    let size: CGFloat
    let duration: Double
    let type: GoldParticleType
    let angle: Double   // for orbit sparks
}
private enum GoldParticleType { case spark, risingCoin, burst }

private struct GoldButtonPreview: View {
    @State private var particles: [GoldParticle] = []
    @State private var activeIDs: Set<Int> = []
    @State private var lavaAngle: Double   = 0   // slow molten surface rotation
    @State private var shimmerX: CGFloat   = -55
    @State private var shimmerOpacity: Double = 0
    @State private var rayAngle: Double     = 0   // slow spin of the sun ray ring
    @State private var shineAngle: Double   = 0   // fast rotating shine streak
    @State private var coreScale: CGFloat   = 1.0
    @State private var flareOpacity: Double = 0
    @State private var flareScale: CGFloat  = 0.6
    @State private var glowPulse: Bool      = false
    @State private var isRunning            = false

    private let sparkTimer   = Timer.publish(every: 0.09, on: .main, in: .common).autoconnect()
    private let shimmerTimer = Timer.publish(every: 1.8,  on: .main, in: .common).autoconnect()
    private let flareTimer   = Timer.publish(every: 2.2,  on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Molten gold base — deep amber core bleeding to burnt orange edge
            Circle()
                .fill(RadialGradient(
                    colors: [
                        Color(red: 1.0,  green: 0.98, blue: 0.55),
                        Color(red: 1.0,  green: 0.78, blue: 0.02),
                        Color(red: 0.88, green: 0.48, blue: 0.0),
                        Color(red: 0.55, green: 0.22, blue: 0.0),
                    ],
                    center: .init(x: 0.42, y: 0.38), startRadius: 0, endRadius: 38
                ))
                .frame(width: 70, height: 70)
                .shadow(color: Color(red: 1.0, green: 0.7, blue: 0.0).opacity(glowPulse ? 1.0 : 0.45), radius: glowPulse ? 28 : 12)
                .animation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true), value: glowPulse)

            // Rotating molten surface pattern — flowing lava veins
            ForEach(0..<3) { i in
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.92, blue: 0.3).opacity(0.35),
                                Color(red: 0.9, green: 0.5, blue: 0.0).opacity(0.15),
                                Color.clear,
                            ],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: 52, height: 10)
                    .blur(radius: 3)
                    .rotationEffect(.degrees(lavaAngle + Double(i) * 60))
            }

            // Hot spot bubbles — random bright blobs that pulse
            ForEach(0..<4) { i in
                let positions: [(CGFloat, CGFloat)] = [(-14,-12),(16,10),(-8,16),(12,-16)]
                Circle()
                    .fill(Color(red: 1.0, green: 0.97, blue: 0.5).opacity(glowPulse ? 0.55 : 0.15))
                    .frame(width: CGFloat([6,5,7,4][i]), height: CGFloat([6,5,7,4][i]))
                    .blur(radius: 2)
                    .offset(x: positions[i].0, y: positions[i].1)
                    .animation(.easeInOut(duration: [0.5, 0.7, 0.45, 0.65][i]).repeatForever(autoreverses: true).delay(Double(i) * 0.12), value: glowPulse)
            }

            // Shimmer sweep
            LinearGradient(
                colors: [Color.clear, Color.white.opacity(0.75), Color.white.opacity(0.4), Color.clear],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(width: 22, height: 70)
            .opacity(shimmerOpacity)
            .offset(x: shimmerX)
            .clipShape(Circle())
            .blendMode(.screen)
            .allowsHitTesting(false)

            // Rotating shine streak — a bright diagonal beam sweeping across the surface
            Capsule()
                .fill(LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.12),
                        Color(red: 1.0, green: 0.97, blue: 0.6).opacity(0.55),
                        Color.white.opacity(0.12),
                        Color.clear,
                    ],
                    startPoint: .leading, endPoint: .trailing
                ))
                .frame(width: 70, height: 3)
                .rotationEffect(.degrees(shineAngle))
                .clipShape(Circle())
                .blendMode(.screen)
                .allowsHitTesting(false)

            // Spark + coin particles
            ForEach(particles.filter { activeIDs.contains($0.id) }) { p in
                GoldParticleView(particle: p)
            }

            // Gloss lens flare
            Ellipse()
                .fill(RadialGradient(
                    colors: [Color.white.opacity(0.65), Color.clear],
                    center: .center, startRadius: 0, endRadius: 12
                ))
                .frame(width: 22, height: 14)
                .offset(x: -10, y: -16)

            // Solar flare burst — expands and fades periodically
            Circle()
                .fill(RadialGradient(
                    colors: [
                        Color(red: 1.0, green: 0.95, blue: 0.4).opacity(0.7),
                        Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.3),
                        Color.clear,
                    ],
                    center: .center, startRadius: 0, endRadius: 18
                ))
                .frame(width: 36 * flareScale, height: 36 * flareScale)
                .opacity(flareOpacity)
                .blur(radius: 4)

            // Radiant sun rays — 8 tapered spikes spinning slowly
            ZStack {
                ForEach(0..<8) { i in
                    // Long sharp ray
                    Capsule()
                        .fill(LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.97, blue: 0.5).opacity(0.0),
                                Color(red: 1.0, green: 0.92, blue: 0.35).opacity(0.85),
                                Color(red: 1.0, green: 0.97, blue: 0.5).opacity(0.0),
                            ],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: CGFloat(i % 2 == 0 ? 22 : 14), height: 1.8)
                        .offset(x: CGFloat(i % 2 == 0 ? 11 : 7))
                        .rotationEffect(.degrees(Double(i) * 45 + rayAngle))
                }
            }

            // Molten core — bright inner sun with slow breath
            ZStack {
                // Outer corona
                Circle()
                    .fill(RadialGradient(
                        colors: [
                            Color(red: 1.0, green: 0.97, blue: 0.55).opacity(0.9),
                            Color(red: 1.0, green: 0.75, blue: 0.0).opacity(0.5),
                            Color.clear,
                        ],
                        center: .center, startRadius: 0, endRadius: 12
                    ))
                    .frame(width: 24 * coreScale, height: 24 * coreScale)
                    .blur(radius: 3)

                // Inner bright point
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.white, Color(red: 1.0, green: 0.95, blue: 0.5), Color.clear],
                        center: .center, startRadius: 0, endRadius: 6
                    ))
                    .frame(width: 12, height: 12)
            }
        }
        .frame(width: 70, height: 70)
        .clipShape(Circle())
        .onAppear {
            isRunning = true
            glowPulse = true
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false))    { lavaAngle  = 360 }
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false))    { rayAngle   = 360 }
            withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false))  { shineAngle = 180 }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { coreScale = 1.18 }
            runShimmer()
            triggerFlare()
            for i in 0..<8 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.07) { spawnParticle() }
            }
        }
        .onDisappear { isRunning = false }
        .onReceive(sparkTimer)   { _ in if isRunning { spawnParticle() } }
        .onReceive(shimmerTimer) { _ in if isRunning { runShimmer() } }
        .onReceive(flareTimer)   { _ in if isRunning { triggerFlare() } }
    }

    private func triggerFlare() {
        flareScale = 0.6; flareOpacity = 0
        withAnimation(.easeOut(duration: 0.18)) { flareOpacity = 0.9; flareScale = 1.0 }
        withAnimation(.easeIn(duration: 0.55).delay(0.18)) { flareOpacity = 0; flareScale = 1.5 }
    }

    private func runShimmer() {
        shimmerX = -55; shimmerOpacity = 0
        withAnimation(.easeIn(duration: 0.15)) { shimmerOpacity = 1.0 }
        withAnimation(.easeInOut(duration: 1.1)) { shimmerX = 62 }
        withAnimation(.easeOut(duration: 0.2).delay(0.95)) { shimmerOpacity = 0 }
    }

    private func spawnParticle() {
        let id   = Int.random(in: 0..<1_000_000)
        let roll = Int.random(in: 0..<3)
        let type: GoldParticleType = roll == 0 ? .risingCoin : (roll == 1 ? .burst : .spark)
        let p = GoldParticle(
            id: id,
            x: CGFloat.random(in: -26...26),
            size: type == .risingCoin ? CGFloat.random(in: 5...9) : CGFloat.random(in: 2...5),
            duration: type == .risingCoin ? Double.random(in: 0.6...1.0) : Double.random(in: 0.25...0.5),
            type: type,
            angle: Double.random(in: 0..<360)
        )
        particles.append(p)
        activeIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + p.duration + 0.12) {
            activeIDs.remove(id)
            particles.removeAll { $0.id == id }
        }
    }
}

private struct GoldParticleView: View {
    let particle: GoldParticle
    @State private var y: CGFloat       = 10
    @State private var x: CGFloat       = 0
    @State private var opacity: Double  = 0
    @State private var rotation: Double = 0
    @State private var scale: CGFloat   = 0.5

    var body: some View {
        Group {
            switch particle.type {
            case .risingCoin:
                // Rotating coin disc with rim shadow
                ZStack {
                    Ellipse()
                        .fill(LinearGradient(
                            colors: [Color(red: 1.0, green: 0.97, blue: 0.45),
                                     Color(red: 0.88, green: 0.62, blue: 0.0)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: particle.size * 0.65, height: particle.size)
                    Ellipse()
                        .strokeBorder(Color(red: 0.55, green: 0.32, blue: 0.0).opacity(0.6), lineWidth: 0.8)
                        .frame(width: particle.size * 0.65, height: particle.size)
                    // Shine line
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: particle.size * 0.18, height: particle.size * 0.6)
                        .offset(x: -particle.size * 0.12)
                        .clipShape(Ellipse().scale(0.9))
                }
                .rotationEffect(.degrees(rotation))
                .opacity(opacity)
                .scaleEffect(scale)
                .offset(x: particle.x, y: y)

            case .burst:
                // 4-point starburst
                ZStack {
                    ForEach(0..<4) { i in
                        Capsule()
                            .fill(Color.white.opacity(0.95))
                            .frame(width: particle.size * 1.8, height: 1.2)
                            .rotationEffect(.degrees(Double(i) * 45 + rotation))
                    }
                    Circle()
                        .fill(Color(red: 1.0, green: 0.97, blue: 0.6))
                        .frame(width: 3, height: 3)
                }
                .opacity(opacity)
                .scaleEffect(scale)
                .offset(x: particle.x, y: y)

            case .spark:
                // Tiny elongated spark shooting upward
                Capsule()
                    .fill(LinearGradient(
                        colors: [Color.white, Color(red: 1.0, green: 0.88, blue: 0.2).opacity(0)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .frame(width: 1.5, height: particle.size * 1.6)
                    .opacity(opacity)
                    .offset(x: particle.x, y: y)
            }
        }
        .onAppear {
            x = particle.x
            withAnimation(.easeOut(duration: 0.08)) { opacity = 1.0; scale = 1.0 }
            withAnimation(.easeOut(duration: particle.duration)) {
                y        = particle.type == .spark ? CGFloat.random(in: -40 ... -22)
                                                   : CGFloat.random(in: -34 ... -16)
                rotation = Double.random(in: 180...540)
                scale    = particle.type == .burst ? 0.2 : 0.8
            }
            withAnimation(.easeIn(duration: 0.22).delay(particle.duration * 0.68)) { opacity = 0 }
        }
    }
}

// MARK: - Ice: arctic freeze — branching frost cracks + snowflake burst + blizzard particles

private struct BlizzardParticle: Identifiable {
    let id: Int
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let size: CGFloat
    let duration: Double
    let isCrystal: Bool   // true = faceted crystal, false = snowflake dot
}

private struct IceButtonPreview: View {
    @State private var blizzard: [BlizzardParticle] = []
    @State private var activeBlizzardIDs: Set<Int>  = []
    @State private var crackAngle: Double  = 0
    @State private var snowAngle: Double   = 0
    @State private var freezePulse: Bool   = false
    // Primary freeze ring
    @State private var iceRingScale: CGFloat    = 1.0
    @State private var iceRingOpacity: Double   = 0
    // Secondary inner freeze ring (offset timing for layered feel)
    @State private var iceRing2Scale: CGFloat   = 1.0
    @State private var iceRing2Opacity: Double  = 0
    // Icicle spikes that radiate outward on freeze pulse
    @State private var icicleScale: CGFloat     = 0.0
    @State private var icicleOpacity: Double    = 0
    @State private var isRunning = false

    private let blizzardTimer = Timer.publish(every: 0.1,  on: .main, in: .common).autoconnect()
    private let ringTimer     = Timer.publish(every: 1.0,  on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Arctic core — near-white with deep-ice blue shadow
            Circle()
                .fill(RadialGradient(
                    colors: [
                        Color.white,
                        Color(red: 0.75, green: 0.93, blue: 1.0),
                        Color(red: 0.35, green: 0.68, blue: 0.92),
                        Color(red: 0.15, green: 0.42, blue: 0.78),
                    ],
                    center: .init(x: 0.38, y: 0.30), startRadius: 0, endRadius: 38
                ))
                .frame(width: 70, height: 70)
                .shadow(color: Color(red: 0.3, green: 0.78, blue: 1.0).opacity(freezePulse ? 1.0 : 0.3), radius: freezePulse ? 26 : 8)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: freezePulse)

            // Frost crack network — thin branching lines radiating from centre
            FrostCrackNetwork(angle: crackAngle)

            // Blizzard particles
            ForEach(blizzard.filter { activeBlizzardIDs.contains($0.id) }) { p in
                BlizzardParticleView(particle: p)
            }

            // Icicle spike burst — 8 sharp diamond spikes that shoot out on freeze
            ZStack {
                ForEach(0..<8) { i in
                    let spikeAngle = Double(i) * 45.0
                    let rad = spikeAngle * .pi / 180
                    // Spike: tapered capsule pointing outward
                    Capsule()
                        .fill(LinearGradient(
                            colors: [
                                Color.white.opacity(0.9),
                                Color(red: 0.6, green: 0.88, blue: 1.0).opacity(0.5),
                                Color.clear,
                            ],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: 16 * icicleScale, height: 2.5)
                        .offset(x: 8 * icicleScale)
                        .rotationEffect(.degrees(spikeAngle))
                    // Secondary mini spike between main spikes
                    Capsule()
                        .fill(Color.white.opacity(0.5 * icicleOpacity))
                        .frame(width: 8 * icicleScale, height: 1.2)
                        .offset(x: 4 * icicleScale)
                        .rotationEffect(.degrees(spikeAngle + 22.5))
                }
            }
            .opacity(icicleOpacity)

            // Secondary inner freeze ring
            Circle()
                .strokeBorder(Color(red: 0.6, green: 0.88, blue: 1.0).opacity(iceRing2Opacity), lineWidth: 1.2)
                .frame(width: 70 * iceRing2Scale, height: 70 * iceRing2Scale)

            // Primary freeze ring
            Circle()
                .strokeBorder(Color.white.opacity(iceRingOpacity), lineWidth: 2)
                .frame(width: 70 * iceRingScale, height: 70 * iceRingScale)

            // Central snowflake — built from lines, no emoji
            ZStack {
                ForEach(0..<6) { i in
                    // Main arm
                    Capsule()
                        .fill(Color.white.opacity(0.95))
                        .frame(width: 18, height: 1.5)
                        .offset(x: 9)
                        .rotationEffect(.degrees(Double(i) * 60 + snowAngle))
                    // Branch left
                    Capsule()
                        .fill(Color.white.opacity(0.75))
                        .frame(width: 6, height: 1)
                        .offset(x: 14, y: 0)
                        .rotationEffect(.degrees(Double(i) * 60 + snowAngle + 35))
                    // Branch right
                    Capsule()
                        .fill(Color.white.opacity(0.75))
                        .frame(width: 6, height: 1)
                        .offset(x: 14, y: 0)
                        .rotationEffect(.degrees(Double(i) * 60 + snowAngle - 35))
                }
                // Centre dot
                Circle()
                    .fill(Color.white)
                    .frame(width: 5, height: 5)
                    .shadow(color: Color(red: 0.5, green: 0.9, blue: 1.0), radius: 4)
            }
            .shadow(color: Color.white, radius: 3)

            // Gloss top-left
            Ellipse()
                .fill(RadialGradient(
                    colors: [Color.white.opacity(0.8), Color.clear],
                    center: .center, startRadius: 0, endRadius: 10
                ))
                .frame(width: 20, height: 13)
                .offset(x: -12, y: -16)
        }
        .frame(width: 70, height: 70)
        .clipShape(Circle())
        .onAppear {
            isRunning   = true
            freezePulse = true
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) { crackAngle = 360 }
            withAnimation(.linear(duration: 7).repeatForever(autoreverses: false))  { snowAngle  = 360 }
            emitRing()
            for i in 0..<8 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.07) { spawnBlizzard() }
            }
        }
        .onDisappear { isRunning = false }
        .onReceive(blizzardTimer) { _ in if isRunning { spawnBlizzard() } }
        .onReceive(ringTimer)     { _ in if isRunning { emitRing() } }
    }

    private func emitRing() {
        // Primary ring
        iceRingScale = 1.0; iceRingOpacity = 0.85
        withAnimation(.easeOut(duration: 0.9)) { iceRingScale = 1.55; iceRingOpacity = 0 }
        // Icicle burst
        icicleScale = 0.0; icicleOpacity = 0
        withAnimation(.easeOut(duration: 0.18)) { icicleScale = 1.0; icicleOpacity = 1.0 }
        withAnimation(.easeIn(duration: 0.5).delay(0.18)) { icicleOpacity = 0 }
        // Secondary ring slightly delayed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            iceRing2Scale = 0.85; iceRing2Opacity = 0.65
            withAnimation(.easeOut(duration: 0.75)) { iceRing2Scale = 1.35; iceRing2Opacity = 0 }
        }
    }

    private func spawnBlizzard() {
        let id    = Int.random(in: 0..<1_000_000)
        // Particles drift diagonally across (wind effect from top-left to bottom-right)
        let startX = CGFloat.random(in: -38...38)
        let startY = CGFloat.random(in: -38...38)
        let drift  = CGFloat.random(in: 10...22)
        let p = BlizzardParticle(
            id: id,
            startX: startX, startY: startY,
            endX: startX + drift, endY: startY + drift,
            size: CGFloat.random(in: 1.5...4.5),
            duration: Double.random(in: 0.55...1.0),
            isCrystal: Bool.random()
        )
        blizzard.append(p)
        activeBlizzardIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + p.duration + 0.1) {
            activeBlizzardIDs.remove(id)
            blizzard.removeAll { $0.id == id }
        }
    }
}

// Procedural frost crack radiating lines
private struct FrostCrackNetwork: View {
    let angle: Double

    var body: some View {
        ZStack {
            ForEach(0..<8) { i in
                let baseAngle = Double(i) * 45.0 + angle * 0.15
                // Main crack
                FrostCrackLine(baseAngle: baseAngle, length: CGFloat.random(in: 18...28), jag: 3)
                // Sub-branch
                FrostCrackLine(baseAngle: baseAngle + 18, length: CGFloat.random(in: 8...14), jag: 2)
            }
        }
        .opacity(0.22)
    }
}

private struct FrostCrackLine: View {
    let baseAngle: Double
    let length: CGFloat
    let jag: CGFloat

    var body: some View {
        let rad = baseAngle * .pi / 180
        let midX = cos(rad) * length * 0.55 + CGFloat.random(in: -jag...jag)
        let midY = sin(rad) * length * 0.55 + CGFloat.random(in: -jag...jag)
        let endX = cos(rad) * length
        let endY = sin(rad) * length
        return Path { p in
            p.move(to: .zero)
            p.addLine(to: CGPoint(x: midX, y: midY))
            p.addLine(to: CGPoint(x: endX, y: endY))
        }
        .stroke(Color.white, style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
    }
}

private struct BlizzardParticleView: View {
    let particle: BlizzardParticle
    @State private var x: CGFloat      = 0
    @State private var y: CGFloat      = 0
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0

    var body: some View {
        Group {
            if particle.isCrystal {
                // Hexagonal facet — two overlapping rectangles
                ZStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: particle.size, height: particle.size * 0.4)
                    Rectangle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: particle.size, height: particle.size * 0.4)
                        .rotationEffect(.degrees(60))
                    Rectangle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: particle.size, height: particle.size * 0.4)
                        .rotationEffect(.degrees(-60))
                }
                .rotationEffect(.degrees(rotation))
                .opacity(opacity)
                .offset(x: x, y: y)
            } else {
                Circle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: particle.size, height: particle.size)
                    .opacity(opacity)
                    .offset(x: x, y: y)
            }
        }
        .onAppear {
            x = particle.startX; y = particle.startY
            withAnimation(.easeIn(duration: 0.1)) { opacity = 0.9 }
            withAnimation(.linear(duration: particle.duration)) {
                x = particle.endX; y = particle.endY
                rotation = Double.random(in: 90...270)
            }
            withAnimation(.easeOut(duration: 0.25).delay(particle.duration * 0.72)) { opacity = 0 }
        }
    }
}

// MARK: - Pirate: cannon fire + cursed ghost fog + skeleton crew

private struct Cannonball: Identifiable {
    let id: Int
    let startX: CGFloat
    let startY: CGFloat
    let angle: Double
    let speed: Double
}

private struct PirateButtonPreview: View {
    @State private var cannonballs: [Cannonball] = []
    @State private var activeCBIDs: Set<Int>     = []
    @State private var ghostFogAngle: Double     = 0
    @State private var skullY: CGFloat           = 0
    @State private var skullTilt: Double         = 0
    @State private var eyeFlicker: Bool          = false
    @State private var dangerPulse: Bool         = false
    @State private var cursedRingScale: CGFloat  = 1.0
    @State private var cursedRingOpacity: Double = 0
    @State private var stormFlash: Double        = 0   // brief white-purple storm lightning flash
    @State private var isRunning = false

    private let cbTimer     = Timer.publish(every: 0.45, on: .main, in: .common).autoconnect()
    private let ringTimer   = Timer.publish(every: 1.1,  on: .main, in: .common).autoconnect()
    private let stormTimer  = Timer.publish(every: 1.6,  on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Abyss — deep night ocean black
            Circle()
                .fill(RadialGradient(
                    colors: [
                        Color(red: 0.16, green: 0.08, blue: 0.28),
                        Color(red: 0.07, green: 0.03, blue: 0.14),
                        Color.black,
                    ],
                    center: .center, startRadius: 0, endRadius: 36
                ))
                .frame(width: 70, height: 70)
                .shadow(color: Color(red: 0.55, green: 0.05, blue: 0.85).opacity(dangerPulse ? 0.95 : 0.25), radius: dangerPulse ? 24 : 8)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: dangerPulse)

            // Cursed ghost fog — slow swirling wisps
            ForEach(0..<5) { i in
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 0.4, green: 0.15, blue: 0.65).opacity(0.25), Color.clear],
                            center: .center, startRadius: 0, endRadius: 20
                        )
                    )
                    .frame(width: CGFloat([44,38,50,36,42][i]), height: CGFloat([12,16,10,14,11][i]))
                    .blur(radius: 6)
                    .rotationEffect(.degrees(ghostFogAngle + Double(i) * 72))
                    .offset(y: CGFloat([-6,4,-3,8,-5][i]))
            }

            // Jolly Roger crossbones — drawn as two crossed bone shapes
            ForEach(0..<2) { i in
                ZStack {
                    // Shaft
                    Capsule()
                        .fill(Color.white.opacity(0.14))
                        .frame(width: 38, height: 4.5)
                    // End knobs
                    Circle().fill(Color.white.opacity(0.14)).frame(width: 7, height: 7).offset(x: -19)
                    Circle().fill(Color.white.opacity(0.14)).frame(width: 7, height: 7).offset(x:  19)
                }
                .rotationEffect(.degrees(i == 0 ? 38 : -38))
            }

            // Cannonball trails
            ForEach(cannonballs.filter { activeCBIDs.contains($0.id) }) { cb in
                CannonballView(ball: cb)
            }

            // Main skull — no emoji, drawn procedurally to avoid square border
            ZStack {
                // Cranium
                Circle()
                    .fill(Color.white.opacity(0.92))
                    .frame(width: 22, height: 22)
                    .offset(y: -2)

                // Jaw block
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.88))
                    .frame(width: 18, height: 9)
                    .offset(y: 8)

                // Teeth gaps — dark notches
                HStack(spacing: 3) {
                    ForEach(0..<4) { _ in
                        Rectangle()
                            .fill(Color.black.opacity(0.7))
                            .frame(width: 2.5, height: 5)
                    }
                }
                .offset(y: 9)

                // Left eye
                Ellipse()
                    .fill(Color.black)
                    .frame(width: 6, height: 7)
                    .overlay(
                        Ellipse()
                            .fill(Color(red: 0.7, green: 0.1, blue: 1.0).opacity(eyeFlicker ? 0.9 : 0.15))
                            .blur(radius: 2)
                            .animation(.easeInOut(duration: 0.35).repeatForever(autoreverses: true), value: eyeFlicker)
                    )
                    .offset(x: -4.5, y: -2)

                // Right eye
                Ellipse()
                    .fill(Color.black)
                    .frame(width: 6, height: 7)
                    .overlay(
                        Ellipse()
                            .fill(Color(red: 0.7, green: 0.1, blue: 1.0).opacity(eyeFlicker ? 0.9 : 0.15))
                            .blur(radius: 2)
                            .animation(.easeInOut(duration: 0.35).delay(0.18).repeatForever(autoreverses: true), value: eyeFlicker)
                    )
                    .offset(x: 4.5, y: -2)

                // Nose hole
                Circle()
                    .fill(Color.black.opacity(0.65))
                    .frame(width: 3.5, height: 3)
                    .offset(y: 4)
            }
            .offset(y: skullY)
            .rotationEffect(.degrees(skullTilt))
            .shadow(color: Color(red: 0.65, green: 0.1, blue: 1.0).opacity(eyeFlicker ? 0.8 : 0.15), radius: 10)

            // Storm lightning flash — whole background momentarily lights up
            Circle()
                .fill(Color(red: 0.7, green: 0.4, blue: 1.0).opacity(stormFlash))
                .frame(width: 70, height: 70)
                .blendMode(.screen)
                .allowsHitTesting(false)

            // Cursed expanding ring
            Circle()
                .strokeBorder(Color(red: 0.6, green: 0.0, blue: 0.9).opacity(cursedRingOpacity), lineWidth: 1.5)
                .frame(width: 70 * cursedRingScale, height: 70 * cursedRingScale)

            // Danger border
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [
                            Color(red: 0.7, green: 0.05, blue: 1.0).opacity(dangerPulse ? 0.9 : 0.15),
                            Color.black.opacity(0.8),
                            Color(red: 0.5, green: 0.0, blue: 0.8).opacity(dangerPulse ? 0.7 : 0.1),
                            Color.black.opacity(0.8),
                            Color(red: 0.7, green: 0.05, blue: 1.0).opacity(dangerPulse ? 0.9 : 0.15),
                        ],
                        center: .center
                    ),
                    lineWidth: 2.5
                )
                .frame(width: 70, height: 70)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: dangerPulse)
        }
        .frame(width: 70, height: 70)
        .clipShape(Circle())
        .onAppear {
            isRunning   = true
            dangerPulse = true
            eyeFlicker  = true
            withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) { ghostFogAngle = 360 }
            withAnimation(.interpolatingSpring(stiffness: 90, damping: 7).repeatForever(autoreverses: true)) {
                skullY = -4; skullTilt = 9
            }
            emitRing()
            triggerStormFlash()
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) { spawnCannonball() }
            }
        }
        .onDisappear { isRunning = false }
        .onReceive(cbTimer)    { _ in if isRunning { spawnCannonball() } }
        .onReceive(ringTimer)  { _ in if isRunning { emitRing() } }
        .onReceive(stormTimer) { _ in if isRunning { triggerStormFlash() } }
    }

    private func triggerStormFlash() {
        // Double-flash like real lightning: bright snap → brief dark → second snap
        stormFlash = 0
        withAnimation(.easeOut(duration: 0.04)) { stormFlash = 0.45 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            withAnimation(.easeOut(duration: 0.06)) { stormFlash = 0.05 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            withAnimation(.easeOut(duration: 0.04)) { stormFlash = 0.35 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeIn(duration: 0.25)) { stormFlash = 0 }
        }
    }

    private func emitRing() {
        cursedRingScale = 0.9; cursedRingOpacity = 0.8
        withAnimation(.easeOut(duration: 0.95)) { cursedRingScale = 1.6; cursedRingOpacity = 0 }
    }

    private func spawnCannonball() {
        let id = Int.random(in: 0..<1_000_000)
        // Fire from random edge of button toward the centre and past it
        let angle = Double.random(in: 0..<360)
        let rad   = angle * .pi / 180
        let edge: CGFloat = 36
        let cb = Cannonball(
            id: id,
            startX:  cos(rad) * edge,
            startY:  sin(rad) * edge,
            angle: angle + 180,   // travel inward
            speed: Double.random(in: 0.3...0.55)
        )
        cannonballs.append(cb)
        activeCBIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + cb.speed + 0.1) {
            activeCBIDs.remove(id)
            cannonballs.removeAll { $0.id == id }
        }
    }
}

private struct CannonballView: View {
    let ball: Cannonball
    @State private var x: CGFloat      = 0
    @State private var y: CGFloat      = 0
    @State private var opacity: Double = 0
    @State private var trailLength: CGFloat = 0

    private let travelDist: CGFloat = 72  // crosses the full button

    var body: some View {
        let rad = ball.angle * .pi / 180
        ZStack {
            // Smoke trail
            Capsule()
                .fill(LinearGradient(
                    colors: [Color.white.opacity(0.0), Color(red: 0.5, green: 0.4, blue: 0.55).opacity(0.4)],
                    startPoint: .trailing, endPoint: .leading
                ))
                .frame(width: trailLength, height: 2.5)
                .rotationEffect(.degrees(ball.angle + 90))
                .offset(
                    x: -cos(rad) * trailLength * 0.5,
                    y: -sin(rad) * trailLength * 0.5
                )
                .blur(radius: 1.5)

            // Iron ball
            Circle()
                .fill(RadialGradient(
                    colors: [Color(red: 0.55, green: 0.55, blue: 0.6), Color(red: 0.2, green: 0.2, blue: 0.22)],
                    center: .init(x: 0.35, y: 0.3), startRadius: 0, endRadius: 4
                ))
                .frame(width: 7, height: 7)
                .shadow(color: Color.black.opacity(0.6), radius: 2)
        }
        .opacity(opacity)
        .offset(x: x, y: y)
        .onAppear {
            x = ball.startX; y = ball.startY
            withAnimation(.easeIn(duration: 0.08)) { opacity = 1.0 }
            withAnimation(.linear(duration: ball.speed)) {
                x = ball.startX + cos(rad) * travelDist
                y = ball.startY + sin(rad) * travelDist
                trailLength = 20
            }
            withAnimation(.easeIn(duration: 0.2).delay(ball.speed * 0.75)) { opacity = 0 }
        }
    }
}

// Classic: smooth glow pulse (no emoji)
private struct ClassicButtonPreview: View {
    @State private var glow: Bool = false
    @State private var ringScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [Color(red: 0.95, green: 0.2, blue: 0.2),
                                               Color(red: 0.7, green: 0.0, blue: 0.15)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 70, height: 70)
                .shadow(color: Color.red.opacity(glow ? 0.8 : 0.3), radius: glow ? 20 : 8)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: glow)

            Circle()
                .strokeBorder(Color.red.opacity(glow ? 0.0 : 0.5), lineWidth: 2)
                .frame(width: 70 * ringScale, height: 70 * ringScale)
                .animation(.easeOut(duration: 1.0).repeatForever(autoreverses: false), value: glow)

            Circle()
                .fill(RadialGradient(colors: [Color.white.opacity(0.25), Color.clear],
                                     center: .init(x: 0.35, y: 0.3),
                                     startRadius: 0, endRadius: 35))
                .frame(width: 70, height: 70)

            Text("TAP")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(width: 70, height: 70)
        .onAppear {
            glow = true
            withAnimation(.easeOut(duration: 1.0).repeatForever(autoreverses: false)) {
                ringScale = 1.4
            }
        }
    }
}

// MARK: - Animated tile previews

private struct AnimatedTilePreview: View {
    let skin: TileSkin

    var body: some View {
        switch skin.id {
        case "fire":   FireTilePreview()
        case "galaxy": GalaxyTilePreview()
        case "neon":   NeonTilePreview()
        case "gold":   GoldTilePreview()
        case "ice":    IceTilePreview()
        case "pirate": PirateTilePreview()
        default:       ClassicTilePreview(skin: skin)
        }
    }
}

// Classic: simple pulsing lit tile
private struct ClassicTilePreview: View {
    let skin: TileSkin
    @State private var lit: Bool = false
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: skin.litColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 70, height: 70)
                .shadow(color: skin.glowColor.opacity(lit ? 0.85 : 0.3), radius: lit ? 18 : 6)
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(skin.glowColor.opacity(lit ? 1.0 : 0.4), lineWidth: lit ? 2.5 : 1))
                .scaleEffect(lit ? 1.06 : 1.0)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: lit)
        }
        .frame(width: 70, height: 70)
        .onAppear { lit = true }
    }
}

// Fire tile: same dense flame + ember system as FireButtonPreview, rounded-rect shape
private struct FireTilePreview: View {
    @State private var particles: [FlameParticle] = []
    @State private var activeIDs: Set<Int> = []
    @State private var glowRadius: CGFloat = 12
    @State private var innerFlame: Bool = false
    @State private var isRunning = false

    private let fastTimer  = Timer.publish(every: 0.09, on: .main, in: .common).autoconnect()
    private let emberTimer = Timer.publish(every: 0.16, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Burned dark core
            RoundedRectangle(cornerRadius: 14)
                .fill(RadialGradient(
                    colors: [
                        Color(red: 0.95, green: 0.35, blue: 0.0),
                        Color(red: 0.7,  green: 0.08, blue: 0.0),
                        Color(red: 0.4,  green: 0.02, blue: 0.0),
                    ],
                    center: .center, startRadius: 0, endRadius: 38
                ))
                .frame(width: 70, height: 70)

            // Breathing outer heat glow
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 1.0, green: 0.3, blue: 0.0).opacity(0.35))
                .frame(width: 70, height: 70)
                .blur(radius: glowRadius)
                .animation(.easeInOut(duration: 0.18).repeatForever(autoreverses: true), value: glowRadius)

            // Flame & ember particles
            ForEach(particles.filter { activeIDs.contains($0.id) }) { p in
                FlameParticleView(particle: p)
            }

            // Inner white-yellow core shimmer
            RoundedRectangle(cornerRadius: 8)
                .fill(RadialGradient(
                    colors: [Color.white.opacity(innerFlame ? 0.45 : 0.15), Color.clear],
                    center: .center, startRadius: 0, endRadius: 22
                ))
                .frame(width: 44, height: 44)
                .animation(.easeInOut(duration: 0.12).repeatForever(autoreverses: true), value: innerFlame)

            // Char border
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.55, blue: 0.0).opacity(0.8), Color.black.opacity(0.5)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 2.5
                )
                .frame(width: 70, height: 70)
        }
        .frame(width: 70, height: 70)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color(red: 1.0, green: 0.35, blue: 0.0).opacity(0.8), radius: 16)
        .onAppear {
            isRunning = true
            glowRadius = 20
            innerFlame = true
            for i in 0..<8 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) { spawnFlame() }
            }
        }
        .onDisappear { isRunning = false }
        .onReceive(fastTimer)  { _ in if isRunning { spawnFlame() } }
        .onReceive(emberTimer) { _ in if isRunning { spawnEmber() } }
    }

    private func spawnFlame() {
        let id = Int.random(in: 0..<1_000_000)
        let p  = FlameParticle(id: id,
                               xStart: CGFloat.random(in: -26...26),
                               xDrift: CGFloat.random(in: -14...14),
                               size: CGFloat.random(in: 14...28),
                               duration: Double.random(in: 0.45...0.75),
                               delay: 0, isEmber: false)
        particles.append(p); activeIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + p.duration + 0.1) {
            activeIDs.remove(id); particles.removeAll { $0.id == id }
        }
    }

    private func spawnEmber() {
        let id = Int.random(in: 0..<1_000_000)
        let p  = FlameParticle(id: id,
                               xStart: CGFloat.random(in: -20...20),
                               xDrift: CGFloat.random(in: -20...20),
                               size: CGFloat.random(in: 3...6),
                               duration: Double.random(in: 0.6...1.1),
                               delay: 0, isEmber: true)
        particles.append(p); activeIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + p.duration + 0.15) {
            activeIDs.remove(id); particles.removeAll { $0.id == id }
        }
    }
}

// Galaxy tile: warp stars zoom from centre outward — same WarpStar system, tile-shaped
private struct GalaxyTilePreview: View {
    @State private var warpStars: [WarpStar] = []
    @State private var activeWarpIDs: Set<Int> = []
    @State private var nebulaAngle: Double = 0
    @State private var corePulse: Bool = false
    @State private var diskSpin: Double = 0
    @State private var isRunning = false

    private let warpTimer = Timer.publish(every: 0.07, on: .main, in: .common).autoconnect()
    private let starColors: [Color] = [
        .white,
        Color(red: 0.88, green: 0.75, blue: 1.0),
        Color(red: 0.65, green: 0.45, blue: 1.0),
        Color(red: 0.55, green: 0.88, blue: 1.0),
        Color(red: 1.0,  green: 0.85, blue: 0.6),
    ]

    var body: some View {
        ZStack {
            // Deep space base
            RoundedRectangle(cornerRadius: 14)
                .fill(RadialGradient(
                    colors: [
                        Color(red: 0.18, green: 0.05, blue: 0.38),
                        Color(red: 0.07, green: 0.02, blue: 0.18),
                        Color.black,
                    ],
                    center: .center, startRadius: 0, endRadius: 40
                ))
                .frame(width: 70, height: 70)
                .shadow(color: Color(red: 0.55, green: 0.2, blue: 1.0).opacity(corePulse ? 0.95 : 0.3), radius: corePulse ? 22 : 8)
                .animation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true), value: corePulse)

            // Nebula dust lanes
            ForEach(0..<4) { i in
                Ellipse()
                    .fill(AngularGradient(
                        colors: [Color(red: 0.6, green: 0.15, blue: 1.0).opacity(0.3), Color(red: 0.2, green: 0.6, blue: 1.0).opacity(0.15), Color.clear],
                        center: .center
                    ))
                    .frame(width: 58, height: 14)
                    .blur(radius: 5)
                    .rotationEffect(.degrees(nebulaAngle + Double(i) * 90))
            }

            // Warp stars
            ForEach(warpStars.filter { activeWarpIDs.contains($0.id) }) { s in
                TileWarpStarView(star: s)
            }

            // Accretion disk ring
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [Color(red: 1.0, green: 0.8, blue: 0.3).opacity(0.9), Color(red: 0.8, green: 0.3, blue: 1.0).opacity(0.6), Color(red: 0.3, green: 0.7, blue: 1.0).opacity(0.7), Color(red: 1.0, green: 0.8, blue: 0.3).opacity(0.9)],
                        center: .center
                    ),
                    lineWidth: 2.5
                )
                .frame(width: 22, height: 22)
                .rotationEffect(.degrees(diskSpin))
                .blur(radius: 1)

            // Black hole core
            Circle().fill(Color.black).frame(width: 10, height: 10)

            // Nucleus glow
            Circle()
                .fill(RadialGradient(
                    colors: [Color.white.opacity(corePulse ? 0.85 : 0.3), Color(red: 0.75, green: 0.4, blue: 1.0).opacity(0.4), Color.clear],
                    center: .center, startRadius: 0, endRadius: 8
                ))
                .frame(width: 16, height: 16)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: corePulse)

            // Border
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color(red: 0.55, green: 0.2, blue: 1.0).opacity(corePulse ? 0.8 : 0.2), lineWidth: 2)
                .frame(width: 70, height: 70)
                .animation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true), value: corePulse)
        }
        .frame(width: 70, height: 70)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color(red: 0.55, green: 0.2, blue: 1.0).opacity(0.65), radius: 14, x: 0, y: 4)
        .onAppear {
            isRunning = true; corePulse = true
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) { nebulaAngle = 360 }
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) { diskSpin = 360 }
            for i in 0..<10 { DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.06) { spawnStar() } }
        }
        .onDisappear { isRunning = false }
        .onReceive(warpTimer) { _ in if isRunning { spawnStar() } }
    }

    private func spawnStar() {
        let id    = Int.random(in: 0..<1_000_000)
        let speed = Double.random(in: 0.35...0.75)
        let s = WarpStar(id: id, angle: Double.random(in: 0..<360), speed: speed,
                         startRadius: CGFloat.random(in: 2...8), size: CGFloat.random(in: 1...3.5),
                         color: starColors.randomElement()!)
        warpStars.append(s); activeWarpIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + speed + 0.1) {
            activeWarpIDs.remove(id); warpStars.removeAll { $0.id == id }
        }
    }
}

// Tile-shaped warp star — same logic as WarpStarView but endRadius fits a 70pt square
private struct TileWarpStarView: View {
    let star: WarpStar
    @State private var progress: CGFloat = 0
    @State private var opacity: Double   = 0
    private let endRadius: CGFloat = 42

    var body: some View {
        ZStack {
            Capsule()
                .fill(LinearGradient(
                    colors: [star.color.opacity(0.0), star.color.opacity(0.55 * opacity)],
                    startPoint: .leading, endPoint: .trailing
                ))
                .frame(width: max(1, (endRadius - star.startRadius) * progress * 0.55),
                       height: max(0.5, star.size * 0.45))
                .offset(x: (star.startRadius + (endRadius - star.startRadius) * progress * 0.72) * cos(star.angle * .pi / 180),
                        y: (star.startRadius + (endRadius - star.startRadius) * progress * 0.72) * sin(star.angle * .pi / 180))
                .rotationEffect(.degrees(star.angle))

            Circle()
                .fill(RadialGradient(colors: [Color.white, star.color.opacity(0.5), .clear],
                                     center: .center, startRadius: 0, endRadius: star.size))
                .frame(width: star.size * 2, height: star.size * 2)
                .opacity(opacity)
                .offset(x: (star.startRadius + (endRadius - star.startRadius) * progress) * cos(star.angle * .pi / 180),
                        y: (star.startRadius + (endRadius - star.startRadius) * progress) * sin(star.angle * .pi / 180))
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.08))             { opacity  = 1.0 }
            withAnimation(.easeIn(duration: star.speed))       { progress = 1.0 }
            withAnimation(.easeOut(duration: 0.2).delay(star.speed * 0.8)) { opacity = 0 }
        }
    }
}

// Neon tile: jagged lightning bolts crackling across the tile surface — same LightningPath system
private struct NeonTilePreview: View {
    @State private var bolts: [LightningBolt] = []
    @State private var activeBoltIDs: Set<Int> = []
    @State private var coreFlicker: Bool = false
    @State private var outerGlow: Bool = false
    @State private var shockScale: CGFloat = 1.0
    @State private var shockOpacity: Double = 0.0
    @State private var isRunning = false

    private let boltTimer  = Timer.publish(every: 0.11, on: .main, in: .common).autoconnect()
    private let shockTimer = Timer.publish(every: 0.7,  on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Dark electric base
            RoundedRectangle(cornerRadius: 14)
                .fill(RadialGradient(
                    colors: [Color(red: 0.0, green: 0.18, blue: 0.22), Color(red: 0.0, green: 0.08, blue: 0.14), Color.black],
                    center: .center, startRadius: 0, endRadius: 42
                ))
                .frame(width: 70, height: 70)
                .shadow(color: Color(red: 0.0, green: 0.95, blue: 0.75).opacity(outerGlow ? 1.0 : 0.3), radius: outerGlow ? 24 : 8)
                .animation(.easeInOut(duration: 0.14).repeatForever(autoreverses: true), value: outerGlow)

            // Shock ring expanding outward
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color(red: 0.0, green: 0.95, blue: 0.75).opacity(shockOpacity), lineWidth: 1.8)
                .frame(width: 70 * shockScale, height: 70 * shockScale)

            // Lightning bolts
            ForEach(bolts.filter { activeBoltIDs.contains($0.id) }) { bolt in
                LightningBoltView(bolt: bolt)
            }

            // Plasma core
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(RadialGradient(
                        colors: [Color.white.opacity(coreFlicker ? 1.0 : 0.3), Color(red: 0.0, green: 0.95, blue: 0.75).opacity(coreFlicker ? 0.8 : 0.2), Color.clear],
                        center: .center, startRadius: 0, endRadius: 14
                    ))
                    .frame(width: 26, height: 26)
                    .blur(radius: 2)
                    .animation(.easeInOut(duration: 0.08).repeatForever(autoreverses: true), value: coreFlicker)

                ForEach(0..<4) { i in
                    Rectangle()
                        .fill(Color.white.opacity(coreFlicker ? 0.9 : 0.3))
                        .frame(width: 12, height: 1.2)
                        .rotationEffect(.degrees(Double(i) * 45))
                        .animation(.easeInOut(duration: 0.09).repeatForever(autoreverses: true), value: coreFlicker)
                }
            }

            // Border flicker
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color(red: 0.0, green: 0.95, blue: 0.75).opacity(outerGlow ? 0.9 : 0.2), lineWidth: 2)
                .frame(width: 70, height: 70)
                .animation(.easeInOut(duration: 0.14).repeatForever(autoreverses: true), value: outerGlow)
        }
        .frame(width: 70, height: 70)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.cyan.opacity(0.7), radius: 14, x: 0, y: 4)
        .onAppear {
            isRunning = true; outerGlow = true; coreFlicker = true
            emitShock()
            for i in 0..<6 { DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) { spawnBolt() } }
        }
        .onDisappear { isRunning = false }
        .onReceive(boltTimer)  { _ in if isRunning { spawnBolt() } }
        .onReceive(shockTimer) { _ in if isRunning { emitShock() } }
    }

    private func emitShock() {
        shockScale = 1.0; shockOpacity = 0.85
        withAnimation(.easeOut(duration: 0.65)) { shockScale = 1.45; shockOpacity = 0 }
    }

    private func spawnBolt() {
        let id    = Int.random(in: 0..<1_000_000)
        let angle = Double.random(in: 0..<360)
        let rad   = angle * .pi / 180
        let segCount = Int.random(in: 3...5)
        var pts: [CGPoint] = [CGPoint(x: 0, y: 0)]
        let totalLen: CGFloat = CGFloat.random(in: 22...32)
        let segLen = totalLen / CGFloat(segCount)
        for seg in 1...segCount {
            let along   = segLen * CGFloat(seg)
            let maxJag: CGFloat = seg == segCount ? 1 : CGFloat.random(in: 4...10)
            let jag     = CGFloat.random(in: -maxJag...maxJag)
            pts.append(CGPoint(x: cos(rad + .pi/2) * jag + cos(rad) * along,
                               y: sin(rad + .pi/2) * jag + sin(rad) * along))
        }
        let useWhite = Bool.random()
        let bolt = LightningBolt(id: id, points: pts,
                                 duration: Double.random(in: 0.08...0.18),
                                 color: useWhite ? .white : Color(red: 0.0, green: 0.95, blue: 0.75),
                                 width: useWhite ? 1.0 : 1.6)
        bolts.append(bolt); activeBoltIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + bolt.duration + 0.05) {
            activeBoltIDs.remove(id); bolts.removeAll { $0.id == id }
        }
    }
}

// Gold tile: molten surface + spark/coin particles + rotating shine — same GoldParticle system
private struct GoldTilePreview: View {
    @State private var particles: [GoldParticle] = []
    @State private var activeIDs: Set<Int> = []
    @State private var lavaAngle: Double   = 0
    @State private var shineAngle: Double  = 0
    @State private var glowPulse: Bool     = false
    @State private var isRunning           = false

    private let sparkTimer = Timer.publish(every: 0.09, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(RadialGradient(
                    colors: [Color(red: 1.0, green: 0.98, blue: 0.55), Color(red: 1.0, green: 0.78, blue: 0.02), Color(red: 0.88, green: 0.48, blue: 0.0), Color(red: 0.55, green: 0.22, blue: 0.0)],
                    center: .init(x: 0.42, y: 0.38), startRadius: 0, endRadius: 42
                ))
                .frame(width: 70, height: 70)
                .shadow(color: Color(red: 1.0, green: 0.7, blue: 0.0).opacity(glowPulse ? 1.0 : 0.45), radius: glowPulse ? 26 : 10)
                .animation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true), value: glowPulse)

            // Molten veins
            ForEach(0..<3) { i in
                Ellipse()
                    .fill(LinearGradient(colors: [Color(red: 1.0, green: 0.92, blue: 0.3).opacity(0.35), Color.clear], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 52, height: 10).blur(radius: 3)
                    .rotationEffect(.degrees(lavaAngle + Double(i) * 60))
            }

            // Rotating shine streak
            Capsule()
                .fill(LinearGradient(colors: [Color.clear, Color.white.opacity(0.55), Color.clear], startPoint: .leading, endPoint: .trailing))
                .frame(width: 70, height: 3)
                .rotationEffect(.degrees(shineAngle))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .blendMode(.screen)

            ForEach(particles.filter { activeIDs.contains($0.id) }) { p in
                GoldParticleView(particle: p)
            }

            // Gloss
            Ellipse()
                .fill(RadialGradient(colors: [Color.white.opacity(0.6), Color.clear], center: .center, startRadius: 0, endRadius: 10))
                .frame(width: 18, height: 12).offset(x: -12, y: -16)

            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(LinearGradient(colors: [Color(red: 1.0, green: 0.9, blue: 0.3).opacity(0.9), Color(red: 0.6, green: 0.3, blue: 0.0).opacity(0.5)], startPoint: .top, endPoint: .bottom), lineWidth: 2.5)
                .frame(width: 70, height: 70)
        }
        .frame(width: 70, height: 70)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color(red: 1.0, green: 0.72, blue: 0.0).opacity(0.75), radius: 14, x: 0, y: 4)
        .onAppear {
            isRunning = true; glowPulse = true
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false))   { lavaAngle  = 360 }
            withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) { shineAngle = 180 }
            for i in 0..<8 { DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.07) { spawnParticle() } }
        }
        .onDisappear { isRunning = false }
        .onReceive(sparkTimer) { _ in if isRunning { spawnParticle() } }
    }

    private func spawnParticle() {
        let id   = Int.random(in: 0..<1_000_000)
        let roll = Int.random(in: 0..<3)
        let type: GoldParticleType = roll == 0 ? .risingCoin : (roll == 1 ? .burst : .spark)
        let p = GoldParticle(id: id, x: CGFloat.random(in: -26...26),
                             size: type == .risingCoin ? CGFloat.random(in: 5...9) : CGFloat.random(in: 2...5),
                             duration: type == .risingCoin ? Double.random(in: 0.6...1.0) : Double.random(in: 0.25...0.5),
                             type: type, angle: Double.random(in: 0..<360))
        particles.append(p); activeIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + p.duration + 0.12) {
            activeIDs.remove(id); particles.removeAll { $0.id == id }
        }
    }
}

// Ice tile: blizzard particles + snowflake + freeze rings — same BlizzardParticle system
private struct IceTilePreview: View {
    @State private var blizzard: [BlizzardParticle] = []
    @State private var activeBlizzardIDs: Set<Int>  = []
    @State private var snowAngle: Double   = 0
    @State private var freezePulse: Bool   = false
    @State private var ringScale: CGFloat  = 1.0
    @State private var ringOpacity: Double = 0
    @State private var isRunning = false

    private let blizzardTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    private let ringTimer     = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Arctic base
            RoundedRectangle(cornerRadius: 14)
                .fill(RadialGradient(
                    colors: [Color.white, Color(red: 0.75, green: 0.93, blue: 1.0), Color(red: 0.35, green: 0.68, blue: 0.92), Color(red: 0.15, green: 0.42, blue: 0.78)],
                    center: .init(x: 0.38, y: 0.30), startRadius: 0, endRadius: 42
                ))
                .frame(width: 70, height: 70)
                .shadow(color: Color(red: 0.3, green: 0.78, blue: 1.0).opacity(freezePulse ? 1.0 : 0.3), radius: freezePulse ? 24 : 8)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: freezePulse)

            // Blizzard particles
            ForEach(blizzard.filter { activeBlizzardIDs.contains($0.id) }) { p in
                BlizzardParticleView(particle: p)
            }

            // Freeze ring
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(ringOpacity), lineWidth: 2)
                .frame(width: 70 * ringScale, height: 70 * ringScale)

            // Central snowflake (6-arm, no emoji)
            ZStack {
                ForEach(0..<6) { i in
                    Capsule()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 16, height: 1.5)
                        .offset(x: 8)
                        .rotationEffect(.degrees(Double(i) * 60 + snowAngle))
                    Capsule()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 5, height: 1)
                        .offset(x: 12)
                        .rotationEffect(.degrees(Double(i) * 60 + snowAngle + 35))
                    Capsule()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 5, height: 1)
                        .offset(x: 12)
                        .rotationEffect(.degrees(Double(i) * 60 + snowAngle - 35))
                }
                Circle().fill(Color.white).frame(width: 4, height: 4)
                    .shadow(color: Color(red: 0.5, green: 0.9, blue: 1.0), radius: 3)
            }
            .shadow(color: Color.white, radius: 2)

            // Gloss
            Ellipse()
                .fill(RadialGradient(colors: [Color.white.opacity(0.7), Color.clear], center: .center, startRadius: 0, endRadius: 8))
                .frame(width: 16, height: 10)
                .offset(x: -10, y: -14)

            // Border
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(LinearGradient(colors: [Color.white, Color(red: 0.6, green: 0.9, blue: 1.0), Color.white],
                                             startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: freezePulse ? 2.5 : 1)
                .frame(width: 70, height: 70)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: freezePulse)
        }
        .frame(width: 70, height: 70)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color(red: 0.4, green: 0.82, blue: 1.0).opacity(0.7), radius: 14, x: 0, y: 4)
        .onAppear {
            isRunning = true; freezePulse = true
            withAnimation(.linear(duration: 7).repeatForever(autoreverses: false)) { snowAngle = 360 }
            emitRing()
            for i in 0..<8 { DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.07) { spawnBlizzard() } }
        }
        .onDisappear { isRunning = false }
        .onReceive(blizzardTimer) { _ in if isRunning { spawnBlizzard() } }
        .onReceive(ringTimer)     { _ in if isRunning { emitRing() } }
    }

    private func emitRing() {
        ringScale = 1.0; ringOpacity = 0.85
        withAnimation(.easeOut(duration: 0.9)) { ringScale = 1.45; ringOpacity = 0 }
    }

    private func spawnBlizzard() {
        let id = Int.random(in: 0..<1_000_000)
        let startX = CGFloat.random(in: -34...34)
        let startY = CGFloat.random(in: -34...34)
        let drift  = CGFloat.random(in: 10...20)
        let p = BlizzardParticle(id: id, startX: startX, startY: startY,
                                 endX: startX + drift, endY: startY + drift,
                                 size: CGFloat.random(in: 1.5...4),
                                 duration: Double.random(in: 0.55...1.0),
                                 isCrystal: Bool.random())
        blizzard.append(p); activeBlizzardIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + p.duration + 0.1) {
            activeBlizzardIDs.remove(id); blizzard.removeAll { $0.id == id }
        }
    }
}

// Lava tile: same dense flame system as fire but deep crimson palette + molten crust surface
// Pirate tile: storm fog + cannonballs + glowing skull — same systems as PirateButtonPreview
private struct PirateTilePreview: View {
    @State private var cannonballs: [Cannonball] = []
    @State private var activeCBIDs: Set<Int>     = []
    @State private var fogAngle: Double          = 0
    @State private var stormFlash: Double        = 0
    @State private var dangerPulse: Bool         = false
    @State private var ringScale: CGFloat        = 1.0
    @State private var ringOpacity: Double       = 0
    @State private var isRunning = false

    private let cbTimer    = Timer.publish(every: 0.5,  on: .main, in: .common).autoconnect()
    private let ringTimer  = Timer.publish(every: 1.1,  on: .main, in: .common).autoconnect()
    private let stormTimer = Timer.publish(every: 1.7,  on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(RadialGradient(
                    colors: [Color(red: 0.16, green: 0.08, blue: 0.28), Color(red: 0.07, green: 0.03, blue: 0.14), Color.black],
                    center: .center, startRadius: 0, endRadius: 42
                ))
                .frame(width: 70, height: 70)
                .shadow(color: Color(red: 0.55, green: 0.05, blue: 0.85).opacity(dangerPulse ? 0.95 : 0.25), radius: dangerPulse ? 22 : 8)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: dangerPulse)

            // Storm flash
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.7, green: 0.4, blue: 1.0).opacity(stormFlash))
                .frame(width: 70, height: 70).blendMode(.screen)

            // Fog wisps
            ForEach(0..<4) { i in
                Ellipse()
                    .fill(Color(red: 0.4, green: 0.15, blue: 0.65).opacity(0.2))
                    .frame(width: 50, height: 16).blur(radius: 6)
                    .rotationEffect(.degrees(fogAngle + Double(i) * 90))
            }

            // Crossbones
            ForEach(0..<2) { i in
                ZStack {
                    Capsule().fill(Color.white.opacity(0.12)).frame(width: 38, height: 4)
                    Circle().fill(Color.white.opacity(0.12)).frame(width: 6, height: 6).offset(x: -19)
                    Circle().fill(Color.white.opacity(0.12)).frame(width: 6, height: 6).offset(x:  19)
                }
                .rotationEffect(.degrees(i == 0 ? 38 : -38))
            }

            // Cannonballs
            ForEach(cannonballs.filter { activeCBIDs.contains($0.id) }) { cb in
                CannonballView(ball: cb)
            }

            // Skull (procedural)
            ZStack {
                Circle().fill(Color.white.opacity(0.88)).frame(width: 18, height: 18).offset(y: -2)
                RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.85)).frame(width: 14, height: 7).offset(y: 7)
                HStack(spacing: 2) { ForEach(0..<3) { _ in Rectangle().fill(Color.black.opacity(0.7)).frame(width: 2, height: 4) } }.offset(y: 8)
                Ellipse().fill(Color.black).frame(width: 5, height: 6)
                    .overlay(Ellipse().fill(Color(red: 0.7, green: 0.1, blue: 1.0).opacity(dangerPulse ? 0.9 : 0.1)).blur(radius: 2)
                        .animation(.easeInOut(duration: 0.35).repeatForever(autoreverses: true), value: dangerPulse))
                    .offset(x: -3.5, y: -2)
                Ellipse().fill(Color.black).frame(width: 5, height: 6)
                    .overlay(Ellipse().fill(Color(red: 0.7, green: 0.1, blue: 1.0).opacity(dangerPulse ? 0.9 : 0.1)).blur(radius: 2)
                        .animation(.easeInOut(duration: 0.35).delay(0.18).repeatForever(autoreverses: true), value: dangerPulse))
                    .offset(x: 3.5, y: -2)
            }
            .shadow(color: Color(red: 0.65, green: 0.1, blue: 1.0).opacity(0.6), radius: 8)

            // Cursed ring
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color(red: 0.6, green: 0.0, blue: 0.9).opacity(ringOpacity), lineWidth: 1.5)
                .frame(width: 70 * ringScale, height: 70 * ringScale)

            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color(red: 0.7, green: 0.05, blue: 1.0).opacity(dangerPulse ? 0.85 : 0.15), lineWidth: 2.5)
                .frame(width: 70, height: 70)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: dangerPulse)
        }
        .frame(width: 70, height: 70)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color(red: 0.55, green: 0.05, blue: 0.85).opacity(0.7), radius: 14, x: 0, y: 4)
        .onAppear {
            isRunning = true; dangerPulse = true
            withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) { fogAngle = 360 }
            emitRing(); triggerStorm()
            for i in 0..<2 { DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.25) { spawnCB() } }
        }
        .onDisappear { isRunning = false }
        .onReceive(cbTimer)    { _ in if isRunning { spawnCB() } }
        .onReceive(ringTimer)  { _ in if isRunning { emitRing() } }
        .onReceive(stormTimer) { _ in if isRunning { triggerStorm() } }
    }

    private func emitRing() {
        ringScale = 0.9; ringOpacity = 0.8
        withAnimation(.easeOut(duration: 0.95)) { ringScale = 1.55; ringOpacity = 0 }
    }

    private func triggerStorm() {
        stormFlash = 0
        withAnimation(.easeOut(duration: 0.04)) { stormFlash = 0.4 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { withAnimation(.easeOut(duration: 0.06)) { stormFlash = 0.05 } }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) { withAnimation(.easeOut(duration: 0.04)) { stormFlash = 0.3 } }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) { withAnimation(.easeIn(duration: 0.25)) { stormFlash = 0 } }
    }

    private func spawnCB() {
        let id    = Int.random(in: 0..<1_000_000)
        let angle = Double.random(in: 0..<360)
        let rad   = angle * .pi / 180
        let cb    = Cannonball(id: id, startX: cos(rad) * 36, startY: sin(rad) * 36,
                               angle: angle + 180, speed: Double.random(in: 0.3...0.55))
        cannonballs.append(cb); activeCBIDs.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + cb.speed + 0.1) {
            activeCBIDs.remove(id); cannonballs.removeAll { $0.id == id }
        }
    }
}

// MARK: - ShopView

struct ShopView: View {
    @EnvironmentObject var coinStore: CoinStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack(alignment: .top) {
            T.bg.ignoresSafeArea()
            LinearGradient(
                colors: [T.accent.opacity(0.12), Color.clear],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.4)
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                ZStack {
                    HStack {
                        HStack(spacing: 5) {
                            GoldCoinIcon(size: 18)
                            Text("\(coinStore.coins)")
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .contentTransition(.numericText())
                                .animation(.spring(response: 0.3), value: coinStore.coins)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(T.card)
                                .overlay(Capsule().strokeBorder(T.highlight.opacity(0.4), lineWidth: 1))
                        )

                        Spacer()

                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(T.secondary)
                                .frame(width: 34, height: 34)
                                .background(Circle().fill(T.surface))
                        }
                    }
                    .padding(.horizontal, 20)

                    Text("SHOP")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(4)
                }
                .padding(.top, 20)
                .padding(.bottom, 20)

                // Tab selector
                HStack(spacing: 0) {
                    shopTab(label: "TAP FRENZY", icon: "hand.tap.fill", index: 0)
                    shopTab(label: "LIGHT IT UP", icon: "bolt.fill",     index: 1)
                }
                .padding(5)
                .background(RoundedRectangle(cornerRadius: 14).fill(T.surface))
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    if selectedTab == 0 {
                        buttonSkinGrid
                    } else {
                        tileSkinGrid
                    }
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
    }

    @ViewBuilder
    private func shopTab(label: String, icon: String, index: Int) -> some View {
        let selected = selectedTab == index
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedTab = index }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                Text(label)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(0.5)
            }
            .foregroundColor(selected ? .black : T.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 11).fill(selected ? T.accent : Color.clear))
        }
        .buttonStyle(.plain)
    }

    private var buttonSkinGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
            ForEach(CoinStore.buttonSkins) { skin in
                ButtonSkinCard(skin: skin)
                    .environmentObject(coinStore)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }

    private var tileSkinGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
            ForEach(CoinStore.tileSkins) { skin in
                TileSkinCard(skin: skin)
                    .environmentObject(coinStore)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
}

// MARK: - Button Skin Card

private struct ButtonSkinCard: View {
    let skin: ButtonSkin
    @EnvironmentObject var coinStore: CoinStore
    @State private var showInsufficient = false

    private var isOwned:    Bool { coinStore.ownedButtonSkins.contains(skin.id) }
    private var isEquipped: Bool { coinStore.equippedButtonSkin == skin.id }
    private var canAfford:  Bool { coinStore.coins >= skin.price }

    var body: some View {
        Button(action: handleTap) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 10) {
                    // Animated preview
                    animatedPreview
                        .frame(width: 70, height: 70)

                    Text(skin.name)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    statusLabel
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(T.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(isEquipped ? T.accent : T.surface,
                                              lineWidth: isEquipped ? 2 : 1)
                        )
                )

                if isEquipped {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(T.accent)
                        .background(Circle().fill(T.card).frame(width: 20, height: 20))
                        .offset(x: -8, y: 8)
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var animatedPreview: some View {
        switch skin.id {
        case "fire":
            FireButtonPreview()
        case "galaxy":
            GalaxyButtonPreview()
                .shadow(color: Color(red: 0.55, green: 0.2, blue: 1.0).opacity(0.7), radius: 14, x: 0, y: 4)
        case "neon":
            NeonButtonPreview()
                .shadow(color: Color.cyan.opacity(0.75), radius: 14, x: 0, y: 4)
        case "gold":
            GoldButtonPreview()
                .shadow(color: Color(red: 1.0, green: 0.72, blue: 0.0).opacity(0.75), radius: 14, x: 0, y: 4)
        case "ice":
            IceButtonPreview()
                .shadow(color: Color(red: 0.4, green: 0.82, blue: 1.0).opacity(0.7), radius: 14, x: 0, y: 4)
        case "pirate":
            PirateButtonPreview()
                .shadow(color: Color(red: 0.55, green: 0.05, blue: 0.85).opacity(0.7), radius: 14, x: 0, y: 4)
        default:
            ClassicButtonPreview()
        }
    }

    @ViewBuilder
    private var statusLabel: some View {
        if showInsufficient {
            HStack(spacing: 2) {
                Text("Not enough")
                GoldCoinIcon(size: 11)
            }
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundColor(Color(red: 1, green: 0.35, blue: 0.35))
        } else if isEquipped {
            HStack(spacing: 3) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 11))
                Text("EQUIPPED")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.5)
            }
            .foregroundColor(T.accent)
        } else if isOwned {
            Text("TAP TO EQUIP")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(T.secondary)
                .tracking(0.5)
        } else if skin.price == 0 {
            Text("FREE")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(T.highlight)
        } else {
            HStack(spacing: 3) {
                GoldCoinIcon(size: 12)
                Text("\(skin.price)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(canAfford ? T.highlight : T.secondary.opacity(0.5))
            }
        }
    }

    private func handleTap() {
        if isEquipped { return }
        if isOwned { coinStore.equipButtonSkin(skin.id); return }
        if coinStore.purchaseButtonSkin(skin.id) {
            coinStore.equipButtonSkin(skin.id)
        } else {
            showInsufficient = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { showInsufficient = false }
        }
    }
}

// MARK: - Tile Skin Card

private struct TileSkinCard: View {
    let skin: TileSkin
    @EnvironmentObject var coinStore: CoinStore
    @State private var showInsufficient = false

    private var isOwned:    Bool { coinStore.ownedTileSkins.contains(skin.id) }
    private var isEquipped: Bool { coinStore.equippedTileSkin == skin.id }
    private var canAfford:  Bool { coinStore.coins >= skin.price }

    var body: some View {
        Button(action: handleTap) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 10) {
                    AnimatedTilePreview(skin: skin)
                        .frame(width: 70, height: 70)

                    Text(skin.name)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    statusLabel
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(T.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(isEquipped ? T.accent : T.surface,
                                              lineWidth: isEquipped ? 2 : 1)
                        )
                )

                if isEquipped {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(T.accent)
                        .background(Circle().fill(T.card).frame(width: 20, height: 20))
                        .offset(x: -8, y: 8)
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var statusLabel: some View {
        if showInsufficient {
            HStack(spacing: 2) {
                Text("Not enough")
                GoldCoinIcon(size: 11)
            }
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundColor(Color(red: 1, green: 0.35, blue: 0.35))
        } else if isEquipped {
            HStack(spacing: 3) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 11))
                Text("EQUIPPED")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.5)
            }
            .foregroundColor(T.accent)
        } else if isOwned {
            Text("TAP TO EQUIP")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(T.secondary)
                .tracking(0.5)
        } else if skin.price == 0 {
            Text("FREE")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(T.highlight)
        } else {
            HStack(spacing: 3) {
                GoldCoinIcon(size: 12)
                Text("\(skin.price)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(canAfford ? T.highlight : T.secondary.opacity(0.5))
            }
        }
    }

    private func handleTap() {
        if isEquipped { return }
        if isOwned { coinStore.equipTileSkin(skin.id); return }
        if coinStore.purchaseTileSkin(skin.id) {
            coinStore.equipTileSkin(skin.id)
        } else {
            showInsufficient = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { showInsufficient = false }
        }
    }
}

#Preview {
    ShopView()
        .environmentObject(CoinStore())
}
