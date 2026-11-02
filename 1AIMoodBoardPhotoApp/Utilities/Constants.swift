//
//  Constants.swift
//  1AIMoodBoardPhotoApp
//

import Foundation
import CoreGraphics

enum Constants {
    /// Replace with your WaveSpeed API key (prefer env/build setting in production).
    static let wavespeedAPIKey = "wsk_live_8IttF47HyCdvxt9E1--aqLhazCn1f7X66qQbEPpRGsU"

    static let maxImageDimension: CGFloat = 1024
    static let jpegQuality: CGFloat = 0.8

    static let pollIntervalSeconds: UInt64 = 2
    /// ~3 min wall clock at 2s interval (nano-banana can take 30–90s).
    static let maxPollAttempts = 90
    /// Status polls are small JSON; keep this tight.
    static let pollRequestTimeoutSeconds: TimeInterval = 45

    /// Per-URL fetch timeout (direct CDN often hangs from RU — fail fast, then try proxies).
    static let outputDownloadRequestTimeoutSeconds: TimeInterval = 20
    static let outputDownloadResourceTimeoutSeconds: TimeInterval = 25
    static let outputDownloadMaxAttempts: Int = 2

    /// Upload to WaveSpeed — dedicated session (avoid URLSession.shared 60s request timeout).
    /// Keep request timeout finite so a stuck socket fails instead of looking hung forever.
    static let uploadRequestTimeoutSeconds: TimeInterval = 60
    static let uploadResourceTimeoutSeconds: TimeInterval = 120
    static let uploadMaxAttempts: Int = 3

    static let onboardingCompletedKey = "onboarding_completed"

    static let aiUseLiveNetwork = true

    /// Generation allotments (prices come from App Store / StoreKit).
    enum GenerationLimits {
        /// Included during StoreKit introductory free trial only.
        static let trial = 1
        /// Per paid weekly billing period.
        static let weekly = 13
        /// Consumable pack size (`generations_5`).
        static let pack = 5
    }

    enum StoreProducts {
        /// Weekly with 3-day free trial (intro offer in App Store Connect).
        static let weeklyTrial = "weekly_premium"
        /// Weekly billed immediately (same subscription group, no intro).
        static let weeklyNow = "weekly_premium_now"
        /// Consumable pack of 5 generations.
        static let generations5 = "generations_5"

        static let subscriptionIDs = [weeklyTrial, weeklyNow]
        /// Legacy ID still recognized for entitlements after older builds.
        static let legacySubscriptionIDs = ["weekly_premium_trial"]
        static let allSubscriptionIDs = subscriptionIDs + legacySubscriptionIDs
        static let all = subscriptionIDs + [generations5]
        static let groupID = "premium_weekly"
    }

    enum CreditsStorage {
        static let consumableBalanceKey = "generation_consumable_balance"
        static let trialUsedKey = "generation_trial_used"
        static let trialOriginalIDKey = "generation_trial_original_id"
        static let weeklyUsedKey = "generation_weekly_used"
        static let weeklyPeriodKey = "generation_weekly_period"
        static let processedConsumableIDsKey = "generation_processed_consumable_ids"
    }
}
