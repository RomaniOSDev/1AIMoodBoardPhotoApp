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
    case mobWife = "Mob Wife"
    case sportyChic = "Sporty Chic"
    case softGlam = "Soft Glam"
    case streetMinimal = "Street Minimal"

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
        case .mobWife:
            return "Mob wife aesthetic, dramatic glamour, bold outerwear, rich textures, evening city mood."
        case .sportyChic:
            return "Sporty chic style, clean athleisure silhouettes, confident posture, modern urban daylight."
        case .softGlam:
            return "Soft glam look, warm flattering light, polished makeup details, elegant feminine styling."
        case .streetMinimal:
            return "Street minimal aesthetic, monochrome palette, sharp lines, editorial urban composition."
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
        case .mobWife: return "sparkles.rectangle.stack"
        case .sportyChic: return "figure.run"
        case .softGlam: return "wand.and.stars"
        case .streetMinimal: return "rectangle.3.group"
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
        case .mobWife: return "mobWife"
        case .sportyChic: return "sportyChic"
        case .softGlam: return "softGlam"
        case .streetMinimal: return "streetMinimal"
        }
    }
}
