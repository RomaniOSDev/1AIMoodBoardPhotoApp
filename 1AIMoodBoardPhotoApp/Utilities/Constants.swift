//
//  Constants.swift
//  1AIMoodBoardPhotoApp
//

import Foundation

enum Constants {
    /// Replace with your WaveSpeed API key (prefer env/build setting in production).
    static let wavespeedAPIKey = "7ccf6b1f435db7e53d022eb21e947bd45062573393457ff5c47d8e3da310dcaf"

    static let bananaProductID = "10_bananas"
    static let initialBananaBalance = 3
    static let generationCost = 1

    static let maxImageDimension: CGFloat = 1024
    static let jpegQuality: CGFloat = 0.8

    static let pollIntervalSeconds: UInt64 = 2
    static let maxPollAttempts = 30

    /// Max wait between bytes (slow CDN / congested links). Must be high or downloads hit `NSURLErrorTimedOut` (-1001).
    static let outputDownloadRequestTimeoutSeconds: TimeInterval = 1200
    /// Total wall time allowed for the full file transfer.
    static let outputDownloadResourceTimeoutSeconds: TimeInterval = 1800
    /// Retries when CloudFront returns transient timeouts.
    static let outputDownloadMaxAttempts: Int = 3

    static let onboardingCompletedKey = "onboarding_completed"

    /// Toggle live WaveSpeed API vs offline mock pipeline (see AIService).
    static let aiUseLiveNetwork = true

    enum BananaKeychain {
        static let service = "home.-AIMoodBoardPhotoApp.bananas"
        static let account = "balance"
    }

    enum Stats {
        static let totalSpentKey = "total_bananas_spent"
    }
}
