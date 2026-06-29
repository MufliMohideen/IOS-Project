//
//  QuizViewModel.swift
//  ios-project
//

import Foundation
import Combine

// MARK: - State Enums

enum QuizState {
    case loading
    case loaded
    case failed(Error)
}

enum AnswerResult {
    case correct
    case wrong
}

// MARK: - ViewModel

@MainActor
final class QuizViewModel: ObservableObject {
    @Published var state: QuizState = .loading
    @Published var questions: [TriviaQuestion] = []
    @Published var currentIndex: Int = 0
    @Published var score: Int = 0
    @Published var streak: Int = 0
    @Published var selectedAnswer: String? = nil
    @Published var answerResult: AnswerResult? = nil
    @Published var isGameOver: Bool = false
    @Published var isNewHighScore: Bool = false

    // Pre-shuffled answers per question — stable across re-renders
    private var shuffledAnswers: [[String]] = []

    var currentAnswers: [String] {
        guard currentIndex < shuffledAnswers.count else { return [] }
        return shuffledAnswers[currentIndex]
    }

    var currentQuestion: TriviaQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    func load() async {
        state = .loading
        isGameOver = false
        currentIndex = 0
        score = 0
        streak = 0
        selectedAnswer = nil
        answerResult = nil
        isNewHighScore = false
        shuffledAnswers = []

        do {
            let fetched = try await QuizService.fetchQuestions()
            questions = fetched
            // Shuffle once per question and store — never re-shuffle on re-render
            shuffledAnswers = fetched.map { q in
                (q.incorrectAnswers + [q.correctAnswer]).shuffled()
            }
            state = .loaded
        } catch {
            state = .failed(error)
        }
    }

    func selectAnswer(_ answer: String) {
        guard selectedAnswer == nil, let question = currentQuestion else { return }
        selectedAnswer = answer

        let isCorrect = answer == question.correctAnswer

        if isCorrect {
            score += 10
            streak += 1
            // Streak bonus every 3 consecutive correct answers
            if streak % 3 == 0 {
                score += 5
            }
            answerResult = .correct
        } else {
            score = max(0, score - 2)
            streak = 0
            answerResult = .wrong
            SoundManager.shared.errorHaptic()
            SoundManager.shared.playError()
        }

        // Auto-advance after 0.8 seconds
        Task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            advance()
        }
    }

    private func advance() {
        let nextIndex = currentIndex + 1
        if nextIndex >= questions.count {
            isGameOver = true
        } else {
            currentIndex = nextIndex
            selectedAnswer = nil
            answerResult = nil
        }
    }

    func markHighScore(current best: Int) {
        if score > best {
            isNewHighScore = true
        }
    }
}
