//
//  QuizService.swift
//  ios-project
//

import Foundation

// MARK: - HTML Entity Decoding

extension String {
    func htmlEntityDecoded() -> String {
        var result = self
        let entities: [(String, String)] = [
            ("&amp;",   "&"),
            ("&quot;",  "\""),
            ("&#039;",  "'"),
            ("&lt;",    "<"),
            ("&gt;",    ">"),
            ("&ldquo;", "\u{201C}"),
            ("&rdquo;", "\u{201D}"),
            ("&lsquo;", "\u{2018}"),
            ("&rsquo;", "\u{2019}"),
            ("&ndash;", "\u{2013}"),
            ("&mdash;", "\u{2014}")
        ]
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        return result
    }
}

// MARK: - Models

struct TriviaQuestion: Identifiable {
    let id = UUID()
    let category: String
    let question: String
    let correctAnswer: String
    let incorrectAnswers: [String]
}

// MARK: - Raw Codable Layer

private struct APIResponse: Codable {
    let responseCode: Int
    let results: [APIResult]

    enum CodingKeys: String, CodingKey {
        case responseCode = "response_code"
        case results
    }
}

private struct APIResult: Codable {
    let category: String
    let question: String
    let correctAnswer: String
    let incorrectAnswers: [String]

    enum CodingKeys: String, CodingKey {
        case category
        case question
        case correctAnswer    = "correct_answer"
        case incorrectAnswers = "incorrect_answers"
    }
}

// MARK: - Service

struct QuizService {
    private static var cachedQuestions: [TriviaQuestion] = []
    private static var lastFetchDate: Date? = nil
    private static let cooldown: TimeInterval = 30

    static func fetchQuestions() async throws -> [TriviaQuestion] {
        // Return cached result if within cooldown window
        if let last = lastFetchDate,
           Date().timeIntervalSince(last) < cooldown,
           !cachedQuestions.isEmpty {
            return cachedQuestions
        }

        let url = URL(string: "https://opentdb.com/api.php?amount=10&type=multiple")!
        let (data, _) = try await URLSession.shared.data(from: url)

        let decoded = try JSONDecoder().decode(APIResponse.self, from: data)
        let questions = decoded.results.map { r in
            TriviaQuestion(
                category: r.category.htmlEntityDecoded(),
                question: r.question.htmlEntityDecoded(),
                correctAnswer: r.correctAnswer.htmlEntityDecoded(),
                incorrectAnswers: r.incorrectAnswers.map { $0.htmlEntityDecoded() }
            )
        }

        cachedQuestions = questions
        lastFetchDate = Date()
        return questions
    }
}
