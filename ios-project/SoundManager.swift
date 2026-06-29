//
//  SoundManager.swift
//  ios-project
//

import AVFoundation
import UIKit

final class SoundManager {
    static let shared = SoundManager()

    private var tapPlayer:      AVAudioPlayer?
    private var successPlayer:  AVAudioPlayer?
    private var errorPlayer:    AVAudioPlayer?
    private var gameOverPlayer: AVAudioPlayer?

    private init() {
        // Ambient session — sounds respect device volume and don't interrupt music
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        tapPlayer      = makePlayer(name: "Tock",     volume: 0.25)
        successPlayer  = makePlayer(name: "positive", volume: 0.30)
        errorPlayer    = makePlayer(name: "negative", volume: 0.28)
        gameOverPlayer = makePlayer(name: "alarm",    volume: 0.28)
    }

    // MARK: - Haptics

    func tapHaptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func successHaptic() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func errorHaptic() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    func heavyHaptic() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    // MARK: - Sounds

    func playTap()      { play(tapPlayer) }
    func playSuccess()  { play(successPlayer) }
    func playError()    { play(errorPlayer) }
    func playGameOver() { play(gameOverPlayer) }

    // MARK: - Private

    private func play(_ player: AVAudioPlayer?) {
        player?.currentTime = 0
        player?.play()
    }

    private func makePlayer(name: String, volume: Float) -> AVAudioPlayer? {
        // System UI sounds live in /System/Library/Audio/UISounds
        let base = "/System/Library/Audio/UISounds"
        let extensions = ["caf", "m4a", "aif"]
        for ext in extensions {
            let url = URL(fileURLWithPath: "\(base)/\(name).\(ext)")
            if let p = try? AVAudioPlayer(contentsOf: url) {
                p.volume = volume
                p.prepareToPlay()
                return p
            }
        }
        return nil
    }
}
