//
//  UploadSelfiesView.swift
//  1AIMoodBoardPhotoApp
//

import SwiftUI

struct UploadSelfiesView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var coordinator: NewShootCoordinator

    @StateObject private var viewModel = UploadSelfiesViewModel()
    private let tipLines = [
        "No sunglasses or heavy makeup",
        "Face clearly visible",
        "Good, natural lighting",
        "Straight-on or slight angle works best for one photo"
    ]

    private var canContinue: Bool {
        viewModel.hasPhoto
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                titleBlock

                photoSlot

                tipsCard
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Step 1 of 3")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    coordinator.resetFlow()
                    dismiss()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                coordinator.selfieImages = viewModel.images
                coordinator.push(.styleSelection)
            } label: {
                CustomButtonView(text: "Continue")
            }
            .buttonStyle(.plain)
            .disabled(!canContinue)
            .padding()
            .background(.ultraThinMaterial)
        }
        .sheet(isPresented: $viewModel.showPicker) {
            ImagePicker(selectionLimit: 1) { picked in
                viewModel.addImages(picked)
            }
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 8) {
            Text("Выбор фото")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text("Add one clear selfie")
                .font(.title2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var photoSlot: some View {
        if let image = viewModel.images.first {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 240)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    viewModel.removePhoto()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.55))
                }
                .padding(10)
            }

            Button("Replace photo") {
                viewModel.showPicker = true
            }
            .font(.subheadline.weight(.medium))
        } else {
            Button {
                viewModel.showPicker = true
            } label: {
                VStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.largeTitle)
                    Text("Add photo")
                        .font(.subheadline.weight(.medium))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                        .foregroundStyle(Color.secondary.opacity(0.5))
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tips for best results")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(tipLines, id: \.self) { line in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .padding(.top, 6)
                        Text(line)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
