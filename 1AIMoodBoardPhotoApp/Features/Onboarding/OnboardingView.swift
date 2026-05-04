//
//  OnboardingView.swift
//  1AIMoodBoardPhotoApp
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var onFinished: () -> Void

    private let pageImages = [
        "onboarding1",
        "onboarding2",
        "onboarding3"
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.backMain.ignoresSafeArea()

                TabView(selection: $viewModel.currentPage) {
                    ForEach(0 ..< pageImages.count, id: \.self) { index in
                        VStack(spacing: 0) {
                            Image(pageImages[index])
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width)
                                .frame(maxHeight: .infinity, alignment: .top)
                            Spacer(minLength: 0)
                        }
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    if viewModel.currentPage < pageImages.count - 1 {
                        withAnimation {
                            viewModel.currentPage += 1
                        }
                    } else {
                        viewModel.completeOnboarding()
                        onFinished()
                    }
                } label: {
                    CustomButtonView(text: "Continue")
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    OnboardingView(viewModel: OnboardingViewModel()) {
        ()
    }
}
