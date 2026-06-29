//
//  ScoreStore.swift
//  ios-project
//

import SwiftUI
import Combine

// MARK: - Score Entry

struct ScoreEntry: Codable, Identifiable {
    let id: UUID
    let score: Int
    let date: Date

    init(score: Int, date: Date = Date()) {
        self.id    = UUID()
        self.score = score
        self.date  = date
    }
}

// MARK: - Store

final class ScoreStore: ObservableObject {
    @Published private(set) var tapFrenzyBest: Int
    @Published private(set) var lightItUpBest: Int
    @Published private(set) var quizRushBest:  Int

    @Published private(set) var tapFrenzyHistory:  [ScoreEntry]
    @Published private(set) var lightItUpHistory:  [ScoreEntry]
    @Published private(set) var quizRushHistory:   [ScoreEntry]

    private let tapKey      = "highScore_tapFrenzy"
    private let litKey      = "highScore_lightItUp"
    private let quizKey     = "highScore_quizRush"
    private let tapHisKey   = "history_tapFrenzy"
    private let litHisKey   = "history_lightItUp"
    private let quizHisKey  = "history_quizRush"

    init() {
        tapFrenzyBest = UserDefaults.standard.integer(forKey: "highScore_tapFrenzy")
        lightItUpBest = UserDefaults.standard.integer(forKey: "highScore_lightItUp")
        quizRushBest  = UserDefaults.standard.integer(forKey: "highScore_quizRush")

        tapFrenzyHistory  = Self.loadHistory(key: "history_tapFrenzy")
        lightItUpHistory  = Self.loadHistory(key: "history_lightItUp")
        quizRushHistory   = Self.loadHistory(key: "history_quizRush")
    }

    // MARK: - Update best + append history

    func updateTapFrenzy(_ score: Int) {
        if score > tapFrenzyBest {
            tapFrenzyBest = score
            UserDefaults.standard.set(score, forKey: tapKey)
        }
        append(score: score, to: &tapFrenzyHistory, key: tapHisKey)
    }

    func updateLightItUp(_ score: Int) {
        if score > lightItUpBest {
            lightItUpBest = score
            UserDefaults.standard.set(score, forKey: litKey)
        }
        append(score: score, to: &lightItUpHistory, key: litHisKey)
    }

    func updateQuizRush(_ score: Int) {
        if score > quizRushBest {
            quizRushBest = score
            UserDefaults.standard.set(score, forKey: quizKey)
        }
        append(score: score, to: &quizRushHistory, key: quizHisKey)
    }

    // MARK: - Private

    private func append(score: Int, to list: inout [ScoreEntry], key: String) {
        let entry = ScoreEntry(score: score)
        list.insert(entry, at: 0)   // newest first
        if list.count > 50 { list = Array(list.prefix(50)) }
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private static func loadHistory(key: String) -> [ScoreEntry] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let list = try? JSONDecoder().decode([ScoreEntry].self, from: data)
        else { return [] }
        return list
    }
}
