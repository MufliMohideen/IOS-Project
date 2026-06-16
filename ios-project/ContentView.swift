//
//  ContentView.swift
//  ios-project
//

import SwiftUI

struct ContentView: View {
    @State private var showPreloader: Bool = true

    var body: some View {
        ZStack {
            if showPreloader {
                PreloaderView {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        showPreloader = false
                    }
                }
                .transition(.opacity)
                .zIndex(1)
            } else {
                HomeView()
                    .transition(.opacity)
                    .zIndex(0)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: showPreloader)
    }
}

#Preview {
    ContentView()
        .environmentObject(ScoreStore())
}
