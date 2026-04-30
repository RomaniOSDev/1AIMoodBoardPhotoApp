//
//  VibePreset.swift
//  1AIMoodBoardPhotoApp
//

import Foundation

/// Ready-made vibes for step 1 (no separate mood-board upload).
enum VibePreset: String, CaseIterable, Identifiable, Hashable, Sendable {
    case cleanGirl = "Clean Girl"
    case oldMoney = "Old Money"
    case darkAcademia = "Dark Academia"
    case y2k = "Y2K"
    case coastal = "Coastal"
    case cottagecore = "Cottagecore"

    var id: String { rawValue }

    /// Text fused into the nano-banana prompt (English).
    var promptFragment: String {
        switch self {
        case .cleanGirl:
            return "Clean-girl aesthetic, neutral palette, polished minimal makeup, natural daylight, tidy modern styling."
        case .oldMoney:
            return "Old money style, timeless tailoring, muted luxury tones, elegant composition, refined atmosphere."
        case .darkAcademia:
            return "Dark academia mood, warm low-key light, classic layers, textured interior tones, cinematic depth."
        case .y2k:
            return "Y2K inspired styling, playful colors, glossy fashion accents, energetic early-2000s vibe."
        case .coastal:
            return "Airy coastal lifestyle, soft blues and whites, relaxed casual layers, natural seaside light."
        case .cottagecore:
            return "Cottagecore mood, soft natural light, floral and earthy details, gentle countryside atmosphere."
        }
    }

    var symbolName: String {
        switch self {
        case .cleanGirl: return "sparkles"
        case .oldMoney: return "briefcase"
        case .darkAcademia: return "book.closed"
        case .y2k: return "star.circle"
        case .coastal: return "sun.haze"
        case .cottagecore: return "leaf"
        }
    }

    var previewAssetName: String {
        switch self {
        case .cleanGirl: return "cleangirl"
        case .oldMoney: return "oldMoney"
        case .darkAcademia: return "darkAcademia"
        case .y2k: return "y2K"
        case .coastal: return "Coastal"
        case .cottagecore: return "Cottagecore"
        }
    }
}
