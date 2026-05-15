//
//  RootView.swift
//  1AIMoodBoardPhotoApp
//

import SwiftUI
import SwiftData

struct RootView: View {
    @EnvironmentObject private var dependencies: AppDependencies
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    @State private var showOnboarding = false
    @State private var selectedTab = 0
    @State private var showWelcomeBananaAlert = false
    @State private var showOutOfBananasOverlay = false

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label {
                            Text(L10n.Tab.home)
                        } icon: {
                            Image(systemName: "house.fill")
                        }
                    }
                    .tag(0)

                MyPhotosView()
                    .tabItem {
                        Label {
                            Text(L10n.Tab.myPhotos)
                        } icon: {
                            Image(systemName: "photo.on.rectangle.angled")
                        }
                    }
                    .tag(1)

                ProfileView()
                    .tabItem {
                        Label {
                            Text(L10n.Tab.profile)
                        } icon: {
                            Image(systemName: "person.fill")
                        }
                    }
                    .tag(2)
            }

            if showWelcomeBananaAlert {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .transition(.opacity)

                WelcomeBananaRewardAlert {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showWelcomeBananaAlert = false
                    }
                }
                .padding(.horizontal, 24)
                .transition(.scale(scale: 0.93).combined(with: .opacity))
                .zIndex(1)
            }

            if showOutOfBananasOverlay {
                Color.black.opacity(0.42)
                    .ignoresSafeArea()
                    .transition(.opacity)

                OutOfBananasOverlay(
                    onClose: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showOutOfBananasOverlay = false
                        }
                    },
                    onPurchase: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showOutOfBananasOverlay = false
                            selectedTab = 2
                        }
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: Notification.Name("openBananaStore"), object: nil)
                        }
                    }
                )
                .padding(.horizontal, 24)
                .transition(.scale(scale: 0.94).combined(with: .opacity))
                .zIndex(2)
            }
        }
        .environment(\.mainTabSelection, $selectedTab)
        .onAppear {
            showOnboarding = !onboardingViewModel.hasCompletedOnboarding
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("showOutOfBananasOverlay"))) { _ in
            guard !showOnboarding else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
                showOutOfBananasOverlay = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(viewModel: onboardingViewModel) {
                showOnboarding = false
                grantFirstLaunchBananaIfNeeded()
            }
        }
    }

    private func grantFirstLaunchBananaIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Constants.firstLaunchBananaGrantedKey) else { return }
        dependencies.bananaManager.addPurchasedBananas(1)
        defaults.set(true, forKey: Constants.firstLaunchBananaGrantedKey)
        withAnimation(.spring(response: 0.34, dampingFraction: 0.85)) {
            showWelcomeBananaAlert = true
        }
    }
}

private struct OutOfBananasOverlay: View {
    let onClose: () -> Void
    let onPurchase: () -> Void

    var body: some View {
        ZStack {
            RewardBananaBackground()
                .allowsHitTesting(false)

            VStack(spacing: 12) {
                Image("bananmini")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)

                Text(L10n.Banana.outTitle)
                    .font(AppFont.custom(26, weight: .bold))
                    .multilineTextAlignment(.center)

                Text(L10n.Banana.outMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)

                Button {
                    onPurchase()
                } label: {
                    CustomButtonView(text: L10n.Banana.goPurchase)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)

                Button {
                    onClose()
                } label: {
                    Text(L10n.Common.close)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(18)
        }
        .frame(maxWidth: 360)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.pinkApp.opacity(0.32), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
                .shadow(color: Color.pinkApp.opacity(0.14), radius: 8, x: 0, y: 0)
        )
    }
}

#Preview {
    let dependencies = AppDependencies()
    RootView()
        .environmentObject(dependencies)
        .modelContainer(dependencies.persistence.container)
}

private struct WelcomeBananaRewardAlert: View {
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            RewardBananaBackground()
                .allowsHitTesting(false)

            VStack(spacing: 12) {
                Image("bananmini")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 46, height: 46)

                Text(L10n.Banana.welcomeTitle)
                    .font(AppFont.custom(28, weight: .bold))
                Text(L10n.Banana.welcomeMessage)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Button {
                    onDismiss()
                } label: {
                    CustomButtonView(text: L10n.Common.continueAction)
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
            .padding(18)
        }
        .frame(maxWidth: 360)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.94))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.pinkApp.opacity(0.32), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 8)
                .shadow(color: Color.pinkApp.opacity(0.14), radius: 8, x: 0, y: 0)
        )
    }
}

private struct RewardBananaBackground: View {
    private struct BananaLayout: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let angle: Double
        let opacity: Double
    }

    private let layouts: [BananaLayout] = [
        .init(id: 0, x: 0.08, y: 0.18, size: 24, angle: -20, opacity: 0.3),
        .init(id: 1, x: 0.26, y: 0.12, size: 32, angle: 14, opacity: 0.24),
        .init(id: 2, x: 0.88, y: 0.2, size: 28, angle: -11, opacity: 0.27),
        .init(id: 3, x: 0.82, y: 0.72, size: 36, angle: 25, opacity: 0.2),
        .init(id: 4, x: 0.14, y: 0.76, size: 30, angle: -30, opacity: 0.25),
        .init(id: 5, x: 0.50, y: 0.88, size: 22, angle: 9, opacity: 0.26)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(layouts) { item in
                    Image("oneBanan")
                        .resizable()
                        .scaledToFit()
                        .frame(width: item.size, height: item.size)
                        .rotationEffect(.degrees(item.angle))
                        .opacity(item.opacity)
                        .position(x: geo.size.width * item.x, y: geo.size.height * item.y)
                }
            }
        }
    }
}
