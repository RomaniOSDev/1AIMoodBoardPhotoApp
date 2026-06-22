//
//  Constants.swift
//  1AIMoodBoardPhotoApp
//

import Foundation
import CoreGraphics

enum Constants {
    /// Replace with your WaveSpeed API key (prefer env/build setting in production).
    static let wavespeedAPIKey = "wsk_live_RfQQm5EOZGc7Tlxo0gBTbRrudB6-uOaoga9_GkcZrU4"

    static let freeTrialDurationDays = 3

    static let maxImageDimension: CGFloat = 1024
    static let jpegQuality: CGFloat = 0.8

    static let pollIntervalSeconds: UInt64 = 2
    static let maxPollAttempts = 30

    static let outputDownloadRequestTimeoutSeconds: TimeInterval = 1200
    static let outputDownloadResourceTimeoutSeconds: TimeInterval = 1800
    static let outputDownloadMaxAttempts: Int = 3

    static let onboardingCompletedKey = "onboarding_completed"

    static let aiUseLiveNetwork = true

    enum SubscriptionProducts {
        /// Weekly with 3-day free trial (intro offer configured in App Store Connect / StoreKit file).
        static let weeklyWithTrial = "weekly_premium_trial"
        /// Weekly billed immediately, no trial.
        static let weeklyNoTrial = "weekly_premium"
        static let all = [weeklyWithTrial, weeklyNoTrial]
        static let groupID = "premium_weekly"
    }

    enum FreeTrial {
        static let endDateKey = "free_trial_end_date"
    }
}
