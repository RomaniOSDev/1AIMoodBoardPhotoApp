//
//  OnboardingView.swift
//  1AIMoodBoardPhotoApp
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var onFinished: () -> Void

    private let pages: [(String, String)] = [
        ("photo.on.rectangle.angled", "Upload 6 selfies"),
        ("rectangle.on.rectangle.angled", "Add mood board from Pinterest"),
        ("sparkles", "Generate lifestyle photos with bananas")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $viewModel.currentPage) {
                ForEach(0 ..< pages.count, id: \.self) { index in
                    VStack(spacing: 24) {
                        Spacer()
                        Image(systemName: pages[index].0)
                            .font(.system(size: 64))
                            .foregroundStyle(.tint)
                        Text(pages[index].1)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button {
                viewModel.completeOnboarding()
                onFinished()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }
}
