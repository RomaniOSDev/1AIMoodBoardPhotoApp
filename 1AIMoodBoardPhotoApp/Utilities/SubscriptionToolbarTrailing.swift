//
//  SubscriptionToolbarTrailing.swift
//  1AIMoodBoardPhotoApp
//

import SwiftUI

/// Top bar status: PRO badge or remaining generations.
struct SubscriptionToolbarTrailing: View {
    @EnvironmentObject private var dependencies: AppDependencies

    var onUpgrade: () -> Void = {}

    var body: some View {
        Button(action: onUpgrade) {
            if dependencies.storeKitManager.isSubscribed {
                HStack(spacing: 6) {
                    Text(L10n.Subscription.proBadge)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                    Text(L10n.Subscription.remainingFormat(dependencies.remainingGenerations))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(Color.pinkApp)
                )
            } else if dependencies.generationCredits.consumableBalance > 0 {
                HStack(spacing: 4) {
                    Text(L10n.Subscription.remainingFormat(dependencies.remainingGenerations))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundStyle(Color.pinkApp)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(.secondarySystemBackground))
                        .overlay(
                            Capsule().stroke(Color.pinkApp.opacity(0.35), lineWidth: 1)
                        )
                )
            } else {
                HStack(spacing: 4) {
                    Text(L10n.Subscription.upgradeBadge)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                    Image(systemName: "crown.fill")
                        .font(.caption)
                        .foregroundStyle(Color.pinkApp)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(.secondarySystemBackground))
                        .overlay(
                            Capsule().stroke(Color.pinkApp.opacity(0.35), lineWidth: 1)
                        )
                )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.Subscription.upgradeA11y)
    }
}
