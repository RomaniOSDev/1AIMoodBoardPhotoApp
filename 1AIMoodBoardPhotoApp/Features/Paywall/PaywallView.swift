//
//  PaywallView.swift
//  1AIMoodBoardPhotoApp
//

import SwiftUI

private enum PaywallAccent {
    static let brown = Color(red: 0.45, green: 0.33, blue: 0.26)
    static let brownLight = Color(red: 0.96, green: 0.94, blue: 0.91)
    static let cardStroke = Color(red: 0.82, green: 0.76, blue: 0.70)
}

struct PaywallView: View {
    @EnvironmentObject private var dependencies: AppDependencies
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var storeKit: StoreKitManager

    @State private var selectedPlan: WeeklySubscriptionPlan = .trial
    @State private var showError = false
    @State private var errorMessage = ""

    var onSubscribed: () -> Void
    var onLimitedAccess: () -> Void

    init(
        storeKit: StoreKitManager,
        onSubscribed: @escaping () -> Void = {},
        onLimitedAccess: @escaping () -> Void = {}
    ) {
        self.storeKit = storeKit
        self.onSubscribed = onSubscribed
        self.onLimitedAccess = onLimitedAccess
    }

    var body: some View {
        ZStack {
            Color.backMain.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    headerRow
                    previewCollage
                    headline
                    planCards
                    limitedLink
                    legalNote
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 120)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                Button {
                    Task { await purchaseSelected() }
                } label: {
                    Text(primaryButtonTitle)
                        .font(AppFont.custom(17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(PaywallAccent.brown)
                        )
                }
                .buttonStyle(.plain)
                .disabled(storeKit.purchaseInProgress)

                footerLinks
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .background(.ultraThinMaterial)
        }
        .overlay {
            if storeKit.purchaseInProgress {
                ProgressView()
                    .scaleEffect(1.2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.12))
            }
        }
        .alert(L10n.Common.error, isPresented: $showError) {
            Button(L10n.Common.ok, role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .task {
            await storeKit.loadProducts()
        }
        .onChange(of: storeKit.isSubscribed) { _, subscribed in
            if subscribed {
                onSubscribed()
                dismiss()
            }
        }
    }

    private var headerRow: some View {
        HStack {
            Spacer()
            Button(L10n.Paywall.restore) {
                Task { await restore() }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(PaywallAccent.brown)
        }
    }

    private var previewCollage: some View {
        HStack(spacing: -28) {
            paywallPreviewImage("cleangirl", rotation: -8)
            paywallPreviewImage("oldMoney", rotation: 4)
                .zIndex(1)
            paywallPreviewImage("softGlam", rotation: 10)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var headline: some View {
        Text(L10n.Paywall.headline)
            .font(AppFont.custom(32, weight: .bold))
            .multilineTextAlignment(.center)
            .foregroundStyle(.primary)
            .padding(.horizontal, 8)
    }

    private var planCards: some View {
        VStack(spacing: 14) {
            planCard(
                plan: .trial,
                badge: L10n.Paywall.freeTrialBadge,
                title: L10n.Paywall.trialTitle,
                priceLine: trialPriceLine,
                subtitle: L10n.Paywall.trialSubtitle
            )

            planCard(
                plan: .noTrial,
                badge: nil,
                title: L10n.Paywall.weekTitle,
                priceLine: weekPriceLine,
                subtitle: L10n.Paywall.weekSubtitle
            )
        }
    }

    @ViewBuilder
    private var limitedLink: some View {
        let trial = dependencies.freeTrialAccess
        if trial.hasUsedTrial && !trial.isActive {
            EmptyView()
        } else {
            Button {
                trial.activate()
                onLimitedAccess()
                dismiss()
            } label: {
                Text(L10n.Paywall.limitedVersion)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }

    private var legalNote: some View {
        Text(L10n.Paywall.legalNote)
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
    }

    private var footerLinks: some View {
        HStack(spacing: 16) {
            linkButton(L10n.Paywall.terms) { openURL(AppLinks.termsOfUse) }
            linkButton(L10n.Paywall.restore) { Task { await restore() } }
            linkButton(L10n.Paywall.privacy) { openURL(AppLinks.privacyPolicy) }
        }
        .font(.caption)
    }

    private var primaryButtonTitle: String {
        selectedPlan == .trial ? L10n.Paywall.startTrialCTA : L10n.Paywall.subscribeCTA
    }

    private var trialPriceLine: String {
        L10n.Paywall.pricePerWeekFormat(storeKit.displayPrice(for: .trial))
    }

    private var weekPriceLine: String {
        L10n.Paywall.pricePerWeekFormat(storeKit.displayPrice(for: .noTrial))
    }

    @ViewBuilder
    private func planCard(
        plan: WeeklySubscriptionPlan,
        badge: String?,
        title: String,
        priceLine: String,
        subtitle: String
    ) -> some View {
        let isSelected = selectedPlan == plan

        Button {
            selectedPlan = plan
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                if let badge {
                    Text(badge)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(PaywallAccent.brown)
                        )
                        .padding(.bottom, 10)
                }

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(priceLine)
                            .font(AppFont.custom(22, weight: .heavy))
                            .foregroundStyle(.primary)
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                        .font(.title2)
                        .foregroundStyle(isSelected ? PaywallAccent.brown : PaywallAccent.cardStroke)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? PaywallAccent.brownLight : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? PaywallAccent.brown : PaywallAccent.cardStroke, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func paywallPreviewImage(_ asset: String, rotation: Double) -> some View {
        Group {
            if let ui = UIImage(named: asset) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.2)
            }
        }
        .frame(width: 108, height: 148)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        .rotationEffect(.degrees(rotation))
    }

    private func linkButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .underline()
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }

    private func purchaseSelected() async {
        do {
            try await storeKit.purchase(plan: selectedPlan)
            if storeKit.isSubscribed {
                onSubscribed()
                dismiss()
            }
        } catch let error as StoreError {
            if case .userCancelled = error { return }
            errorMessage = error.localizedDescription ?? ""
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func restore() async {
        do {
            try await storeKit.restorePurchases()
            if storeKit.isSubscribed {
                onSubscribed()
                dismiss()
            } else {
                errorMessage = L10n.Paywall.restoreNoSubscription
                showError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    PaywallView(storeKit: StoreKitManager())
        .environmentObject(AppDependencies())
}
