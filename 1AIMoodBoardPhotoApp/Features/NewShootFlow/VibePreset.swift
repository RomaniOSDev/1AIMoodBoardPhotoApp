//
//  VibePreset.swift
//  1AIMoodBoardPhotoApp
//

import Foundation

/// Ready-made vibes for step 1 (no separate mood-board upload).
enum VibePreset: String, CaseIterable, Identifiable, Hashable, Sendable {
    case goldenHour = "Golden hour"
    case editorialMagazine = "Editorial magazine"
    case coastalWeekend = "Coastal weekend"
    case minimalStudio = "Minimal studio"
    case urbanStreet = "Urban street"
    case softRomantic = "Soft romantic"

    var id: String { rawValue }

    /// Text fused into the nano-banana prompt (English).
    var promptFragment: String {
        switch self {
        case .goldenHour:
            return "Warm golden-hour sunlight, soft flattering light, dreamy outdoor lifestyle, shallow depth of field."
        case .editorialMagazine:
            return "High-fashion editorial lighting, magazine-cover energy, polished wardrobe, relaxed confident stance."
        case .coastalWeekend:
            return "Bright airy coastal vibe, soft blues and whites, relaxed weekend styling, casual layers, ocean-town stroll."
        case .minimalStudio:
            return "Clean minimal studio background, soft even lighting, understated wardrobe, calm aesthetic."
        case .urbanStreet:
            return "Urban street-style energy, city bokeh, casual trendy outfit, candid lifestyle moment."
        case .softRomantic:
            return "Soft romantic palette, gentle diffused light, elegant understated wardrobe, gentle portrait mood."
        }
    }
}
