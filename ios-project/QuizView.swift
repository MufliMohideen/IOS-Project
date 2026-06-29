//
//  QuizView.swift
//  ios-project
//

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

// MARK: - Game Gradient Background

private struct GameBackground: View {
    let accentColor: Color
    let secondaryColor: Color
    @State private var drift = false

    var body: some View {
        ZStack {
            T.bg.ignoresSafeArea()

            // Top-center vertical spotlight
            LinearGradient(
                colors: [accentColor.opacity(0.14), accentColor.opacity(0.04), Color.clear],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.5)
            )
            .ignoresSafeArea()

            // Top-right orb
            Ellipse()
                .fill(RadialGradient(
                    colors: [accentColor.opacity(0.35), Color.clear],
                    center: .center, startRadius: 0, endRadius: 180
                ))
                .frame(width: 300, height: 260)
                .blur(radius: 72)
                .offset(x: drift ? 140 : 120, y: drift ? -300 : -320)
                .animation(.easeInOut(duration: 9).repeatForever(autoreverses: true), value: drift)

            // Bottom-left orb
            Ellipse()
                .fill(RadialGradient(
                    colors: [secondaryColor.opacity(0.22), Color.clear],
                    center: .center, startRadius: 0, endRadius: 160
                ))
                .frame(width: 260, height: 240)
                .blur(radius: 68)
                .offset(x: drift ? -130 : -110, y: drift ? 360 : 380)
                .animation(.easeInOut(duration: 11).repeatForever(autoreverses: true), value: drift)
        }
        .onAppear { drift = true }
    }
}

// MARK: - View

struct QuizView: View {
    @EnvironmentObject var scoreStore: ScoreStore
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = QuizViewModel()
    @State private var showHelp: Bool = false

    var body: some View {
        ZStack {
            GameBackground(accentColor: T.accent, secondaryColor: T.highlight)

            switch viewModel.state {
            case .loading:
                loadingView

            case .failed(let error):
                failedView(error: error)

            case .loaded:
                if viewModel.isGameOver {
                    gameOverView
                        .transition(.opacity)
                } else {
                    gameView
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: viewModel.isGameOver)
        .navigationBarHidden(true)
        .task { await viewModel.load() }
        .sheet(isPresented: $showHelp) {
            quizHelpSheet
        }
        .onChange(of: viewModel.isGameOver) { over in
            if over {
                viewModel.markHighScore(current: scoreStore.quizRushBest)
                if viewModel.isNewHighScore {
                    scoreStore.updateQuizRush(viewModel.score)
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            topBar(showHelp: false)
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: T.accent))
                .scaleEffect(1.4)
            Text("LOADING QUESTIONS...")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(T.secondary)
                .tracking(3)
                .padding(.top, 12)
            Spacer()
        }
    }

    // MARK: - Failed View

    private func failedView(error: Error) -> some View {
        VStack(spacing: 20) {
            topBar(showHelp: false)
            Spacer()
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 44))
                .foregroundColor(T.secondary)
            Text("FAILED TO LOAD")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .tracking(3)
            Text(error.localizedDescription)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(T.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button(action: { Task { await viewModel.load() } }) {
                Text("RETRY")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .tracking(2)
                    .foregroundColor(.black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Color.white))
            }
            Spacer()
        }
    }

    // MARK: - Game View

    private var gameView: some View {
        VStack(spacing: 0) {
            topBar(showHelp: true)

            // Progress + streak row
            HStack(spacing: 12) {
                Text("\(viewModel.currentIndex + 1) OF \(viewModel.questions.count)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(T.secondary)
                    .tracking(2)

                if viewModel.streak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("\(viewModel.streak) STREAK")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1)
                    }
                    .foregroundColor(T.highlight)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(T.highlight.opacity(0.12))
                            .overlay(Capsule().strokeBorder(T.highlight.opacity(0.35), lineWidth: 1))
                    )
                }

                Spacer()

                // Score pill
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(T.highlight.opacity(0.8))
                    Text("\(viewModel.score)")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.25), value: viewModel.score)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(T.card)
                        .overlay(Capsule().strokeBorder(T.accent.opacity(0.4), lineWidth: 1))
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 16)

            // Question card
            if let question = viewModel.currentQuestion {
                VStack(alignment: .leading, spacing: 10) {
                    Text(question.category.uppercased())
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(T.accent.opacity(0.8))
                        .tracking(2)

                    Text(question.question)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(T.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(T.accent.opacity(0.5), lineWidth: 1.5)
                        )
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                // Answer buttons
                VStack(spacing: 12) {
                    ForEach(viewModel.currentAnswers, id: \.self) { answer in
                        answerButton(answer: answer, question: question)
                    }
                }
                .padding(.horizontal, 20)
                .disabled(viewModel.selectedAnswer != nil)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private func answerButton(answer: String, question: TriviaQuestion) -> some View {
        let isSelected = viewModel.selectedAnswer == answer
        let isCorrect  = answer == question.correctAnswer
        let revealed   = viewModel.selectedAnswer != nil
        let isWrong    = revealed && isSelected && !isCorrect

        let fillColor: Color = {
            if !revealed { return T.surface }
            if isCorrect { return Color.green.opacity(0.18) }
            if isSelected { return Color.red.opacity(0.18) }
            return T.surface
        }()

        let strokeColor: Color = {
            if !revealed { return T.card }
            if isCorrect { return Color.green.opacity(0.7) }
            if isSelected { return Color.red.opacity(0.7) }
            return T.card
        }()

        let iconName: String? = {
            if !revealed { return nil }
            if isCorrect { return "checkmark.circle.fill" }
            if isSelected { return "xmark.circle.fill" }
            return nil
        }()

        let iconColor: Color = isCorrect ? .green : .red

        AnswerButtonRow(
            answer: answer,
            fillColor: fillColor,
            strokeColor: strokeColor,
            iconName: iconName,
            iconColor: iconColor,
            isWrong: isWrong,
            onTap: { viewModel.selectAnswer(answer) }
        )
        .disabled(revealed)
    }

    // MARK: - Game Over View

    private var gameOverView: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("HOME")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .tracking(1)
                    }
                    .foregroundColor(T.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(T.surface)
                            .overlay(Capsule().strokeBorder(T.card, lineWidth: 1))
                    )
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)

            Spacer()

            VStack(spacing: 12) {
                Image(systemName: viewModel.isNewHighScore ? "trophy.fill" : "flag.checkered")
                    .font(.system(size: 52))
                    .foregroundStyle(
                        viewModel.isNewHighScore
                        ? LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [Color.white.opacity(0.6), Color.white.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: viewModel.isNewHighScore ? Color.yellow.opacity(0.5) : Color.clear, radius: 16)

                Text(viewModel.isNewHighScore ? "NEW BEST!" : "GAME OVER")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(viewModel.isNewHighScore ? Color.yellow.opacity(0.9) : T.secondary)
                    .tracking(5)
            }
            .padding(.bottom, 28)

            VStack(spacing: 4) {
                Text("\(viewModel.score)")
                    .font(.system(size: 96, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [Color.white, Color.white.opacity(0.75)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: T.accent.opacity(0.3), radius: 20)
                Text("POINTS")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(T.secondary)
                    .tracking(5)
            }

            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundColor(T.highlight.opacity(0.8))
                Text("BEST  \(scoreStore.quizRushBest)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(T.secondary)
                    .tracking(3)
            }
            .padding(.top, 10)
            .padding(.bottom, 44)

            Button(action: { Task { await viewModel.load() } }) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .bold))
                    Text("PLAY AGAIN")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .tracking(1)
                }
                .foregroundColor(.black)
                .padding(.horizontal, 48)
                .padding(.vertical, 17)
                .background(
                    Capsule()
                        .fill(Color.white)
                        .shadow(color: Color.white.opacity(0.25), radius: 16, y: 6)
                )
            }

            Spacer()
        }
    }

    // MARK: - Top Bar

    @ViewBuilder
    private func topBar(showHelp: Bool) -> some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("HOME")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .tracking(1)
                }
                .foregroundColor(T.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(T.surface)
                        .overlay(Capsule().strokeBorder(T.card, lineWidth: 1))
                )
            }

            Spacer()

            if showHelp {
                Button(action: { self.showHelp = true }) {
                    Image(systemName: "questionmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(T.secondary)
                        .frame(width: 34, height: 34)
                        .background(
                            Circle()
                                .fill(T.surface)
                                .overlay(Circle().strokeBorder(T.card, lineWidth: 1))
                        )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
        .padding(.bottom, 8)
    }

    // MARK: - Help Sheet

    private var quizHelpSheet: some View {
        ZStack {
            T.bg.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("HOW TO PLAY")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(4)
                    .padding(.top, 32)

                VStack(alignment: .leading, spacing: 14) {
                    helpRow(icon: "questionmark.circle.fill", text: "Answer 10 trivia questions")
                    helpRow(icon: "checkmark.circle.fill", text: "+10 points for a correct answer")
                    helpRow(icon: "xmark.circle.fill", text: "-2 points for a wrong answer")
                    helpRow(icon: "flame.fill", text: "+5 bonus every 3 correct in a row")
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .presentationDetents([.medium])
    }

    private func helpRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(T.accent)
                .frame(width: 26)
            Text(text)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(T.secondary)
        }
    }
}

// MARK: - Answer Button Row

private struct AnswerButtonRow: View {
    let answer: String
    let fillColor: Color
    let strokeColor: Color
    let iconName: String?
    let iconColor: Color
    let isWrong: Bool
    let onTap: () -> Void

    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon slot — always 16pt wide so layout never shifts
                ZStack {
                    if let name = iconName {
                        Image(systemName: name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(iconColor)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 16, height: 16)

                Text(answer)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(fillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(strokeColor, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .offset(x: shakeOffset)
        .animation(.easeInOut(duration: 0.15), value: fillColor)
        .onChange(of: isWrong) { wrong in
            guard wrong else { return }
            shake()
        }
    }

    private func shake() {
        let duration = 0.06
        withAnimation(.easeInOut(duration: duration)) { shakeOffset = -8 }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation(.easeInOut(duration: duration)) { shakeOffset = 8 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration * 2) {
            withAnimation(.easeInOut(duration: duration)) { shakeOffset = -6 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration * 3) {
            withAnimation(.easeInOut(duration: duration)) { shakeOffset = 6 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration * 4) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { shakeOffset = 0 }
        }
    }
}

#Preview {
    QuizView()
        .environmentObject(ScoreStore())
}
