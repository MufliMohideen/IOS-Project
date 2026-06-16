//
//  SoundManager.swift
//  ios-project
//

import AVFoundation
import UIKit

final class SoundManager {
    static let shared = SoundManager()
    private init() {}

    // MARK: - Haptics

    func tapHaptic() {
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()
    }

    func successHaptic() {
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
    }

    func errorHaptic() {
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.error)
    }

    func heavyHaptic() {
        let gen = UIImpactFeedbackGenerator(style: .heavy)
        gen.impactOccurred()
    }

    // MARK: - Sounds

    func playTap() {
        AudioServicesPlaySystemSound(1104)
    }

    func playSuccess() {
        AudioServicesPlaySystemSound(1025)
    }

    func playError() {
        AudioServicesPlaySystemSound(1053)
    }

    func playGameOver() {
        AudioServicesPlaySystemSound(1005)
    }
}
