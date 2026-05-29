//
//  AIProcessingConsent.swift
//  1AIMoodBoardPhotoApp
//

import Foundation

/// User consent before sending photos and prompts to a third-party AI provider.
enum AIProcessingConsent {
    static let grantedKey = "ai_processing_consent_granted"

    static var hasGranted: Bool {
        UserDefaults.standard.bool(forKey: grantedKey)
    }

    static func grant() {
        UserDefaults.standard.set(true, forKey: grantedKey)
        print("[AIProcessingConsent] granted")
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: grantedKey)
        print("[AIProcessingConsent] reset")
    }
}
