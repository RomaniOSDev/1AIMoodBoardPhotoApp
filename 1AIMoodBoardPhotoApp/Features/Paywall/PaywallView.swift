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
                                .fill(canPurchaseSelectedPlan ? PaywallAccent.brown : PaywallAccent.brown.opacity(0.45))
                        )
                }
                .buttonStyle(.plain)
                .disabled(storeKit.purchaseInProgress || !canPurchaseSelectedPlan)

                if storeKit.isProductAvailable, storeKit.isEligibleForIntroOffer {
                    Text(L10n.Paywall.trialDisclosure)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PaywallAccent.brown)
                }

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
            if let loadError = storeKit.loadErrorMessage {
                productsStatusBanner(message: loadError)
            }

            if storeKit.isProductAvailable {
                planCard(priceLine: weekPriceLine, subtitle: cardSubtitle)
            }
        }
    }

    private var cardSubtitle: String {
        storeKit.isEligibleForIntroOffer
            ? L10n.Paywall.trialPriceSubtitle(storeKit.displayPrice)
            : L10n.Paywall.weekPriceSubtitle(storeKit.displayPrice)
    }

    private var canPurchaseSelectedPlan: Bool {
        storeKit.isProductAvailable
    }

    private func productsStatusBanner(message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Task { await storeKit.loadProducts() }
            } label: {
                Text(L10n.Paywall.reloadProducts)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PaywallAccent.brown)
            }
            .buttonStyle(.plain)
            .disabled(storeKit.purchaseInProgress)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
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
        L10n.Paywall.subscribePriceCTA(storeKit.displayPrice)
    }

    private var weekPriceLine: String {
        storeKit.displayPrice
    }

    @ViewBuilder
    private func planCard(priceLine: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(priceLine)
                    .font(AppFont.custom(26, weight: .heavy))
                    .foregroundStyle(.primary)
                Text(L10n.Paywall.perWeekSuffix)
                    .font(AppFont.custom(15, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(PaywallAccent.brownLight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(PaywallAccent.brown, lineWidth: 1.5)
        )
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
        guard storeKit.isProductAvailable else {
            errorMessage = L10n.Store.errorUnavailable
            showError = true
            return
        }

        do {
            try await storeKit.purchase()
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
