//
//  ContentView.swift
//  ios-project
//

import SwiftUI

struct ContentView: View {
    @State private var showPreloader: Bool = true
    @State private var homeOpacity: Double  = 0
    @State private var homeScale: CGFloat   = 0.88

    var body: some View {
        ZStack {
            HomeView()
                .opacity(homeOpacity)
                .scaleEffect(homeScale)
                .zIndex(0)

            if showPreloader {
                PreloaderView {
                    // Snap HomeView in with a tight spring — feels instant and punchy
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                        homeOpacity = 1.0
                        homeScale   = 1.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showPreloader = false
                    }
                }
                .zIndex(1)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ScoreStore())
        .environmentObject(CoinStore())
}
