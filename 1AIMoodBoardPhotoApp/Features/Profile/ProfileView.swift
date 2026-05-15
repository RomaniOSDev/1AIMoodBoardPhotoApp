//
//  ProfileView.swift
//  1AIMoodBoardPhotoApp
//

import StoreKit
import SwiftData
import SwiftUI
import UIKit

struct ProfileView: View {
    @EnvironmentObject private var dependencies: AppDependencies
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var bananaManager = BananaManager.shared

    @StateObject private var viewModel = ProfileViewModel()
    @State private var libraryPhotoCount = 0
    @State private var showBananaStore = false
    @State private var showResetConfirmation = false

    var body: some View {
        ZStack {
            Color.backMain.ignoresSafeArea()

            
                ScrollView {
                    VStack(spacing: 14) {
                    HStack {
                        Text(L10n.Profile.title)
                            .font(AppFont.custom(32, weight: .bold))

                        Spacer()

                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundStyle(.pinkApp)
                            .opacity(0.7)
                    }

                        ProfileCard(title: L10n.Profile.cardBananas) {
                            HStack {
                                Text(L10n.Profile.balance)
                                Spacer()
                                Image("bananmini")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                Text("\(bananaManager.balance)")
                                    .font(.title2.bold())
                            }
                            .padding(.bottom, 6)

                            Button {
                                showBananaStore = true
                            } label: {
                                ProfileActionButtonLabel(
                                    title: L10n.Profile.buyBananas,
                                    icon: "cart.fill"
                                )
                            }
                            .buttonStyle(.plain)

                            Button {
                                Task { await viewModel.restore(dependencies: dependencies) }
                            } label: {
                                ProfileActionButtonLabel(
                                    title: L10n.Profile.restore,
                                    icon: "arrow.clockwise"
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(dependencies.storeKitManager.purchaseInProgress)

                            if let loadError = dependencies.storeKitManager.loadErrorMessage {
                                Text(loadError)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 2)

                                Button {
                                    Task { await dependencies.storeKitManager.loadProducts() }
                                } label: {
                                    ProfileActionButtonLabel(
                                        title: L10n.Profile.reloadProducts,
                                        icon: "arrow.triangle.2.circlepath"
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(dependencies.storeKitManager.purchaseInProgress)
                            }
                        }

                        ProfileCard(title: L10n.Profile.activity) {
                            HStack {
                                Text(L10n.Profile.generationsLibrary)
                                Spacer()
                                Text("\(libraryPhotoCount)")
                                    .foregroundStyle(.secondary)
                            }
                            HStack {
                                Text(L10n.Profile.bananasSpent)
                                Spacer()
                                Text("\(bananaManager.totalBananasSpentStatistic)")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        ProfileCard(title: L10n.Profile.support) {
                            Button {
                                rateApp()
                            } label: {
                                ProfileActionButtonLabel(title: L10n.Profile.rate, icon: "star.fill")
                            }
                            .buttonStyle(.plain)

                            Button {
                                openURL(AppLinks.privacyPolicy)
                            } label: {
                                ProfileActionButtonLabel(title: L10n.Profile.privacy, icon: "lock.fill")
                            }
                            .buttonStyle(.plain)

                            Button {
                                openURL(AppLinks.termsOfUse)
                            } label: {
                                ProfileActionButtonLabel(title: L10n.Profile.terms, icon: "doc.text.fill")
                            }
                            .buttonStyle(.plain)
                        }

                        ProfileCard(title: L10n.Profile.danger) {
                            Button(role: .destructive) {
                                showResetConfirmation = true
                            } label: {
                                ProfileActionButtonLabel(
                                    title: L10n.Profile.resetAll,
                                    icon: "trash.fill",
                                    destructive: true
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 2)
                        }
                    }
                    .padding()
                }
                .onAppear {
                    libraryPhotoCount = viewModel.generationCount(repository: dependencies.repository(context: modelContext))
                }
                .alert(L10n.Profile.alertPurchase, isPresented: $viewModel.showPurchaseError) {
                    Button(L10n.Common.ok, role: .cancel) {}
                } message: {
                    Text(viewModel.purchaseErrorMessage)
                }
                .alert(L10n.Profile.alertRestore, isPresented: $viewModel.showRestoreAlert) {
                    Button(L10n.Common.ok, role: .cancel) {}
                } message: {
                    Text(viewModel.restoreMessage)
                }
                .alert(L10n.Profile.alertReset, isPresented: $viewModel.showResetAlert) {
                    Button(L10n.Common.ok, role: .cancel) {}
                } message: {
                    Text(viewModel.resetMessage)
                }
                .confirmationDialog(
                    L10n.Profile.resetDialogTitle,
                    isPresented: $showResetConfirmation,
                    titleVisibility: .visible
                ) {
                    Button(L10n.Profile.resetAll, role: .destructive) {
                        Task {
                            let didReset = await viewModel.resetAllData(
                                dependencies: dependencies,
                                modelContext: modelContext
                            )
                            if didReset {
                                libraryPhotoCount = 0
                            }
                        }
                    }
                    Button(L10n.Common.cancel, role: .cancel) {}
                }
                .sheet(isPresented: $showBananaStore) {
                    BananaStoreSheetView(dependencies: dependencies, viewModel: viewModel)
                        .presentationDetents([.fraction(0.75), .large])
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("openBananaStore"))) { _ in
                    showBananaStore = true
                }
            
        }
    }

    private func openURL(_ value: String) {
        if let url = URL(string: value) {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

private struct ProfileCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                Text(title)
                                    .font(AppFont.custom(24, weight: .heavy))
                                Spacer()
                            }
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.secondarySystemBackground),
                            Color(.secondarySystemBackground).opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.pinkApp.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                .shadow(color: Color.pinkApp.opacity(0.1), radius: 4, x: 0, y: 0)
        )
    }
}

private struct ProfileActionButtonLabel: View {
    let title: String
    let icon: String
    var destructive: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
        }
        .foregroundStyle(destructive ? .red : .primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(destructive ? Color.red.opacity(0.08) : Color.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            destructive ? Color.red.opacity(0.35) : Color.white.opacity(0.18),
                            lineWidth: 1
                        )
                )
        )
    }
}

private struct ProfilePreviewHost: View {
    let dependencies = AppDependencies()

    var body: some View {
        ProfileView()
            .environmentObject(dependencies)
            .modelContainer(dependencies.persistence.container)
    }
}

#Preview {
    ProfilePreviewHost()
}


