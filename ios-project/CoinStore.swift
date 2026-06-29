//
//  CoinStore.swift
//  ios-project
//

import SwiftUI
import Combine

// MARK: - Cosmetic Models

struct ButtonSkin: Identifiable {
    let id: String
    let name: String
    let emoji: String
    let price: Int
    let colors: [Color]
    let glowColor: Color
}

struct TileSkin: Identifiable {
    let id: String
    let name: String
    let emoji: String
    let price: Int
    let litColors: [Color]
    let glowColor: Color
}

// MARK: - CoinStore

final class CoinStore: ObservableObject {

    // MARK: - Static skin catalogues

    static let buttonSkins: [ButtonSkin] = [
        ButtonSkin(id: "default", name: "Classic",  emoji: "",   price: 0,
                   colors: [Color(red: 0.95, green: 0.2, blue: 0.2), Color(red: 0.7, green: 0.0, blue: 0.15)],
                   glowColor: Color.red.opacity(0.55)),
        ButtonSkin(id: "pirate",  name: "Pirate",   emoji: "☠️", price: 200,
                   colors: [Color(red: 0.15, green: 0.12, blue: 0.22), Color(red: 0.08, green: 0.06, blue: 0.14)],
                   glowColor: Color(red: 0.5, green: 0.3, blue: 0.8).opacity(0.6)),
        ButtonSkin(id: "fire",    name: "Fire",      emoji: "🔥", price: 150,
                   colors: [Color(red: 1.0, green: 0.45, blue: 0.0), Color(red: 0.85, green: 0.15, blue: 0.0)],
                   glowColor: Color.orange.opacity(0.65)),
        ButtonSkin(id: "galaxy",  name: "Galaxy",    emoji: "🌌", price: 300,
                   colors: [Color(red: 0.28, green: 0.10, blue: 0.55), Color(red: 0.12, green: 0.05, blue: 0.35)],
                   glowColor: Color(red: 0.55, green: 0.35, blue: 1.0).opacity(0.65)),
        ButtonSkin(id: "neon",    name: "Neon",      emoji: "⚡", price: 250,
                   colors: [Color(red: 0.0, green: 0.85, blue: 0.95), Color(red: 0.0, green: 0.55, blue: 0.85)],
                   glowColor: Color.cyan.opacity(0.7)),
        ButtonSkin(id: "gold",    name: "Gold",      emoji: "👑", price: 400,
                   colors: [Color(red: 1.0, green: 0.80, blue: 0.15), Color(red: 0.85, green: 0.55, blue: 0.0)],
                   glowColor: Color.yellow.opacity(0.65)),
        ButtonSkin(id: "ice",     name: "Ice",       emoji: "❄️", price: 200,
                   colors: [Color(red: 0.75, green: 0.92, blue: 1.0), Color(red: 0.45, green: 0.75, blue: 0.95)],
                   glowColor: Color(red: 0.6, green: 0.88, blue: 1.0).opacity(0.65)),
    ]

    static let tileSkins: [TileSkin] = [
        TileSkin(id: "default", name: "Classic",  emoji: "",   price: 0,
                 litColors: [Color(red: 0.25, green: 0.55, blue: 1.0).opacity(0.9), Color(red: 0.25, green: 0.55, blue: 1.0).opacity(0.6)],
                 glowColor: Color(red: 0.25, green: 0.55, blue: 1.0)),
        TileSkin(id: "fire",    name: "Fire",     emoji: "🔥", price: 150,
                 litColors: [Color(red: 1.0, green: 0.45, blue: 0.0).opacity(0.9), Color(red: 0.85, green: 0.15, blue: 0.0).opacity(0.6)],
                 glowColor: Color.orange),
        TileSkin(id: "galaxy",  name: "Galaxy",   emoji: "✨", price: 300,
                 litColors: [Color(red: 0.75, green: 0.25, blue: 0.98).opacity(0.9), Color(red: 0.45, green: 0.10, blue: 0.75).opacity(0.6)],
                 glowColor: Color(red: 0.75, green: 0.25, blue: 0.98)),
        TileSkin(id: "neon",    name: "Neon",     emoji: "⚡", price: 250,
                 litColors: [Color(red: 0.0, green: 0.95, blue: 0.75).opacity(0.9), Color(red: 0.0, green: 0.65, blue: 0.45).opacity(0.6)],
                 glowColor: Color(red: 0.0, green: 0.95, blue: 0.75)),
        TileSkin(id: "gold",    name: "Gold",     emoji: "",   price: 400,
                 litColors: [Color(red: 1.0, green: 0.88, blue: 0.15).opacity(0.9), Color(red: 0.88, green: 0.52, blue: 0.0).opacity(0.6)],
                 glowColor: Color(red: 1.0, green: 0.78, blue: 0.0)),
        TileSkin(id: "ice",     name: "Ice",      emoji: "",   price: 200,
                 litColors: [Color(red: 0.82, green: 0.97, blue: 1.0).opacity(0.9), Color(red: 0.35, green: 0.68, blue: 0.92).opacity(0.6)],
                 glowColor: Color(red: 0.4, green: 0.82, blue: 1.0)),
        TileSkin(id: "pirate",  name: "Pirate",   emoji: "",   price: 200,
                 litColors: [Color(red: 0.22, green: 0.08, blue: 0.38).opacity(0.9), Color(red: 0.07, green: 0.02, blue: 0.18).opacity(0.6)],
                 glowColor: Color(red: 0.6, green: 0.1, blue: 0.9)),
    ]

    // MARK: - Published state (arrays instead of Set to satisfy ObservableObject synthesis)

    @Published var coins: Int = 0
    @Published var ownedButtonSkinIDs: [String] = ["default"]
    @Published var ownedTileSkinIDs: [String]   = ["default"]
    @Published var equippedButtonSkin: String    = "default"
    @Published var equippedTileSkin: String      = "default"

    // MARK: - Convenience set-based accessors

    var ownedButtonSkins: Set<String> { Set(ownedButtonSkinIDs) }
    var ownedTileSkins:   Set<String> { Set(ownedTileSkinIDs) }

    // MARK: - Keys

    private let coinsKey          = "coins"
    private let ownedButtonKey    = "ownedButtonSkins"
    private let ownedTileKey      = "ownedTileSkins"
    private let equippedButtonKey = "equippedButtonSkin"
    private let equippedTileKey   = "equippedTileSkin"

    // MARK: - Init

    init() {
        coins              = UserDefaults.standard.integer(forKey: coinsKey)
        equippedButtonSkin = UserDefaults.standard.string(forKey: equippedButtonKey) ?? "default"
        equippedTileSkin   = UserDefaults.standard.string(forKey: equippedTileKey)   ?? "default"

        let rawButton = UserDefaults.standard.stringArray(forKey: ownedButtonKey) ?? []
        let rawTile   = UserDefaults.standard.stringArray(forKey: ownedTileKey)   ?? []
        ownedButtonSkinIDs = Array(Set(rawButton).union(["default"]))
        ownedTileSkinIDs   = Array(Set(rawTile).union(["default"]))
    }

    // MARK: - Coins

    func addCoins(_ amount: Int) {
        coins += amount
        UserDefaults.standard.set(coins, forKey: coinsKey)
    }

    @discardableResult
    func spend(_ amount: Int) -> Bool {
        guard coins >= amount else { return false }
        coins -= amount
        UserDefaults.standard.set(coins, forKey: coinsKey)
        return true
    }

    // MARK: - Score → Coin conversion

    func convertScore(tapFrenzy score: Int) {
        addCoins(score)
    }

    func convertScore(lightItUp score: Int) {
        addCoins(score * 2)
    }

    func convertScore(quizRush score: Int) {
        addCoins(score)
    }

    // MARK: - Button skins

    @discardableResult
    func purchaseButtonSkin(_ id: String) -> Bool {
        guard !ownedButtonSkins.contains(id),
              let skin = CoinStore.buttonSkins.first(where: { $0.id == id }),
              spend(skin.price) else { return false }
        ownedButtonSkinIDs.append(id)
        saveOwned()
        return true
    }

    func equipButtonSkin(_ id: String) {
        guard ownedButtonSkins.contains(id) else { return }
        equippedButtonSkin = id
        UserDefaults.standard.set(id, forKey: equippedButtonKey)
    }

    // MARK: - Tile skins

    @discardableResult
    func purchaseTileSkin(_ id: String) -> Bool {
        guard !ownedTileSkins.contains(id),
              let skin = CoinStore.tileSkins.first(where: { $0.id == id }),
              spend(skin.price) else { return false }
        ownedTileSkinIDs.append(id)
        saveOwned()
        return true
    }

    func equipTileSkin(_ id: String) {
        guard ownedTileSkins.contains(id) else { return }
        equippedTileSkin = id
        UserDefaults.standard.set(id, forKey: equippedTileKey)
    }

    // MARK: - Private

    private func saveOwned() {
        UserDefaults.standard.set(ownedButtonSkinIDs, forKey: ownedButtonKey)
        UserDefaults.standard.set(ownedTileSkinIDs,   forKey: ownedTileKey)
    }
}
