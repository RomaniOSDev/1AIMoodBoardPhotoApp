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

    @State private var selectedKind: StoreProductKind?
    @State private var showError = false
    @State private var errorMessage = ""

    var onSubscribed: () -> Void

    init(
        storeKit: StoreKitManager,
        onSubscribed: @escaping () -> Void = {}
    ) {
        self.storeKit = storeKit
        self.onSubscribed = onSubscribed
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
                .padding(.bottom, 140)
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
                                .fill(canPurchase ? PaywallAccent.brown : PaywallAccent.brown.opacity(0.45))
                        )
                }
                .buttonStyle(.plain)
                .disabled(storeKit.purchaseInProgress || !canPurchase)

                if let selectedKind, selectedKind == .weeklyTrial {
                    Text(L10n.Paywall.trialIncludesOneGeneration)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PaywallAccent.brown)
                        .multilineTextAlignment(.center)
                }

                if showWaitHint {
                    Text(L10n.Paywall.waitTrialEndsHint)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
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
            syncSelection()
        }
        .onChange(of: storeKit.productsByID.keys.description) { _, _ in
            syncSelection()
        }
        .onChange(of: storeKit.isSubscribed) { _, _ in
            syncSelection()
        }
        .onChange(of: storeKit.isInIntroOfferPeriod) { _, _ in
            syncSelection()
        }
        .onChange(of: dependencies.canGeneratePhoto) { _, canGenerate in
            guard canGenerate else { return }
            // Stay open during intro with 0 trial credits so user can pick pay-now / pack.
            if storeKit.isInIntroOfferPeriod,
               dependencies.generationCredits.subscriptionCreditsRemaining(
                isSubscribed: true,
                isInIntroOffer: true
               ) == 0,
               dependencies.generationCredits.consumableBalance == 0 {
                return
            }
            onSubscribed()
            dismiss()
        }
    }

    private var availableKinds: [StoreProductKind] {
        var kinds: [StoreProductKind] = []

        if storeKit.isSubscribed && storeKit.isInIntroOfferPeriod {
            // Trial active / exhausted: allow upgrade to paid + pack.
            if storeKit.isProductAvailable(.weeklyNow) { kinds.append(.weeklyNow) }
            if storeKit.isProductAvailable(.generations5) { kinds.append(.generations5) }
        } else if storeKit.isSubscribed {
            // Paid period, out of weekly credits → pack only.
            if storeKit.isProductAvailable(.generations5) { kinds.append(.generations5) }
        } else {
            if storeKit.isEligibleForIntroOffer, storeKit.isProductAvailable(.weeklyTrial) {
                kinds.append(.weeklyTrial)
            }
            if storeKit.isProductAvailable(.weeklyNow) {
                kinds.append(.weeklyNow)
            }
            if storeKit.isProductAvailable(.generations5) {
                kinds.append(.generations5)
            }
        }

        return kinds
    }

    private var canPurchase: Bool {
        guard let selectedKind else { return false }
        return storeKit.isProductAvailable(selectedKind)
    }

    private var showWaitHint: Bool {
        storeKit.isSubscribed && storeKit.isInIntroOfferPeriod && !dependencies.canGeneratePhoto
    }

    private var primaryButtonTitle: String {
        guard let selectedKind else { return L10n.Paywall.subscribeNowCTA("—") }
        switch selectedKind {
        case .weeklyTrial:
            return L10n.Paywall.startTrialCTA(storeKit.displayPrice(for: .weeklyTrial))
        case .weeklyNow:
            return L10n.Paywall.subscribeNowCTA(storeKit.displayPrice(for: .weeklyNow))
        case .generations5:
            return L10n.Paywall.buyPackCTA(storeKit.displayPrice(for: .generations5))
        }
    }

    private func syncSelection() {
        let kinds = availableKinds
        if let selectedKind, kinds.contains(selectedKind) { return }
        selectedKind = kinds.first
    }

    private var headerRow: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(PaywallAccent.brown)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(PaywallAccent.brownLight))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.Common.close)

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
            if let loadError = storeKit.loadErrorMessage, availableKinds.isEmpty {
                productsStatusBanner(message: loadError)
            }

            ForEach(availableKinds) { kind in
                selectableCard(for: kind)
            }
        }
    }

    @ViewBuilder
    private func selectableCard(for kind: StoreProductKind) -> some View {
        let isSelected = selectedKind == kind
        Button {
            selectedKind = kind
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title(for: kind))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(priceLine(for: kind))
                        .font(AppFont.custom(22, weight: .heavy))
                        .foregroundStyle(.primary)
                    Text(subtitle(for: kind))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? PaywallAccent.brown : PaywallAccent.cardStroke)
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

    private func title(for kind: StoreProductKind) -> String {
        switch kind {
        case .weeklyTrial: return L10n.Paywall.trialPlanTitle
        case .weeklyNow: return L10n.Paywall.paidPlanTitle
        case .generations5: return L10n.Paywall.packTitle
        }
    }

    private func priceLine(for kind: StoreProductKind) -> String {
        let price = storeKit.displayPrice(for: kind)
        switch kind {
        case .weeklyTrial, .weeklyNow:
            return "\(price)\(L10n.Paywall.perWeekSuffix)"
        case .generations5:
            return price
        }
    }

    private func subtitle(for kind: StoreProductKind) -> String {
        switch kind {
        case .weeklyTrial:
            return L10n.Paywall.planSubtitle(storeKit.displayPrice(for: .weeklyTrial))
        case .weeklyNow:
            return L10n.Paywall.paidPlanSubtitle(storeKit.displayPrice(for: .weeklyNow))
        case .generations5:
            return L10n.Paywall.packSubtitle
        }
    }

    private func productsStatusBanner(message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Task {
                    await storeKit.loadProducts()
                    syncSelection()
                }
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
        guard let kind = selectedKind else { return }
        guard storeKit.isProductAvailable(kind) else {
            errorMessage = L10n.Store.errorUnavailable
            showError = true
            return
        }

        do {
            try await storeKit.purchase(kind)
            syncSelection()

            // After upgrade out of intro, user should have weekly credits.
            if kind == .weeklyNow, storeKit.isSubscribed, !storeKit.isInIntroOfferPeriod {
                onSubscribed()
                dismiss()
                return
            }

            if kind == .generations5, dependencies.generationCredits.consumableBalance > 0 {
                onSubscribed()
                dismiss()
                return
            }

            if kind == .weeklyTrial, storeKit.isSubscribed {
                onSubscribed()
                dismiss()
                return
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
            syncSelection()
            if storeKit.isSubscribed || dependencies.canGeneratePhoto {
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
