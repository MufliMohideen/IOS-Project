//
//  ios_projectApp.swift
//  ios-project
//
//  Created by Mufli Mohideen on 2026-06-10.
//

import SwiftUI

@main
struct ios_projectApp: App {
    @StateObject var scoreStore = ScoreStore()
    @StateObject var coinStore  = CoinStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(scoreStore)
                .environmentObject(coinStore)
        }
    }
}
