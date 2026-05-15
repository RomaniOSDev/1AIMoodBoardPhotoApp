//
//  OnboardingView.swift
//  1AIMoodBoardPhotoApp
//

import SwiftUI

private struct OnboardingPageModel: Identifiable {
    let id: Int
    let assetName: String
    let title: String
    let bullets: [String]
}

struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var onFinished: () -> Void

    private var pages: [OnboardingPageModel] {
        [
            OnboardingPageModel(
                id: 0,
                assetName: "onboarding1",
                title: L10n.Onboard.Page1.title,
                bullets: [L10n.Onboard.Page1.b1, L10n.Onboard.Page1.b2, L10n.Onboard.Page1.b3]
            ),
            OnboardingPageModel(
                id: 1,
                assetName: "onboarding2",
                title: L10n.Onboard.Page2.title,
                bullets: [L10n.Onboard.Page2.b1, L10n.Onboard.Page2.b2, L10n.Onboard.Page2.b3]
            ),
            OnboardingPageModel(
                id: 2,
                assetName: "onboarding3",
                title: L10n.Onboard.Page3.title,
                bullets: [L10n.Onboard.Page3.b1, L10n.Onboard.Page3.b2, L10n.Onboard.Page3.b3]
            ),
            OnboardingPageModel(
                id: 3,
                assetName: "onboarding1",
                title: L10n.Onboard.Page4.title,
                bullets: [L10n.Onboard.Page4.b1, L10n.Onboard.Page4.b2, L10n.Onboard.Page4.b3]
            )
        ]
    }

    private var isLastPage: Bool {
        viewModel.currentPage == pages.count - 1
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.backMain.ignoresSafeArea()

                TabView(selection: $viewModel.currentPage) {
                    ForEach(pages) { page in
                        OnboardingPageContent(page: page, availableHeight: geo.size.height)
                            .tag(page.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 18) {
                    pageIndicator

                    Button {
                        if isLastPage {
                            viewModel.completeOnboarding()
                            onFinished()
                        } else {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                viewModel.currentPage += 1
                            }
                        }
                    } label: {
                        CustomButtonView(text: isLastPage ? L10n.Common.getStarted : L10n.Common.continueAction)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(pages) { page in
                Capsule()
                    .fill(viewModel.currentPage == page.id ? Color.pinkApp : Color.secondary.opacity(0.25))
                    .frame(width: viewModel.currentPage == page.id ? 22 : 7, height: 7)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.currentPage)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            L10n.Onboard.pageAccessibility(current: viewModel.currentPage + 1, total: pages.count)
        )
    }
}

private struct OnboardingPageContent: View {
    let page: OnboardingPageModel
    let availableHeight: CGFloat

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Image(page.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: max(200, availableHeight * 0.34))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)

                Text(page.title)
                    .font(AppFont.custom(28, weight: .bold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(page.bullets.enumerated()), id: \.offset) { _, line in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.body)
                                .foregroundStyle(Color.pinkApp)
                                .accessibilityHidden(true)

                            Text(line)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 120)
        }
    }
}

#Preview {
    OnboardingView(viewModel: OnboardingViewModel()) {
        ()
    }
}
