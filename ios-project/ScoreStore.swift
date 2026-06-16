//
//  ScoreStore.swift
//  ios-project
//

import SwiftUI
import Combine

final class ScoreStore: ObservableObject {
    @Published private(set) var tapFrenzyBest: Int
    @Published private(set) var lightItUpBest: Int

    private let tapKey  = "highScore_tapFrenzy"
    private let litKey  = "highScore_lightItUp"

    init() {
        tapFrenzyBest = UserDefaults.standard.integer(forKey: "highScore_tapFrenzy")
        lightItUpBest = UserDefaults.standard.integer(forKey: "highScore_lightItUp")
    }

    func updateTapFrenzy(_ score: Int) {
        guard score > tapFrenzyBest else { return }
        tapFrenzyBest = score
        UserDefaults.standard.set(score, forKey: tapKey)
    }

    func updateLightItUp(_ score: Int) {
        guard score > lightItUpBest else { return }
        lightItUpBest = score
        UserDefaults.standard.set(score, forKey: litKey)
    }
}
