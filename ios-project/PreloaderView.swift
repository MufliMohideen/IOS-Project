//
//  PreloaderView.swift
//  ios-project
//

import SwiftUI

struct PreloaderView: View {
    let onComplete: () -> Void

    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.18

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.06, blue: 0.10),
                         Color(red: 0.04, green: 0.04, blue: 0.08)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Pulsing circle behind title
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.9, green: 0.2, blue: 0.2).opacity(0.35), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 320, height: 320)
                .scaleEffect(pulseScale)
                .opacity(pulseOpacity)
                .animation(
                    .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                    value: pulseScale
                )

            VStack(spacing: 18) {
                Text("TAP ARENA")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(6)
                    .shadow(color: Color(red: 1, green: 0.3, blue: 0.3).opacity(0.6), radius: 20)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                Text("READY YOUR FINGERS")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(5)
                    .opacity(subtitleOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
                pulseOpacity = 0.28
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.55)) {
                subtitleOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                onComplete()
            }
        }
    }
}

#Preview {
    PreloaderView(onComplete: {})
}
