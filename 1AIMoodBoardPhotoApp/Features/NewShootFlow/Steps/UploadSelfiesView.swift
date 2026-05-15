//
//  UploadSelfiesView.swift
//  1AIMoodBoardPhotoApp
//

import SwiftUI

struct UploadSelfiesView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var coordinator: NewShootCoordinator

    @StateObject private var viewModel = UploadSelfiesViewModel()
    private var tipLines: [String] {
        [L10n.Shoot.tip1, L10n.Shoot.tip2, L10n.Shoot.tip3, L10n.Shoot.tip4]
    }

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
                Text(L10n.Shoot.step1)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    coordinator.resetFlow()
                    dismiss()
                } label: {
                    Label {
                        Text(L10n.Common.back)
                    } icon: {
                        Image(systemName: "chevron.left")
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                coordinator.selfieImages = viewModel.images
                coordinator.push(.styleSelection)
            } label: {
                CustomButtonView(text: L10n.Common.continueAction)
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
            Text(L10n.Shoot.selfieTitle)
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text(L10n.Shoot.selfieSubtitle)
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

            Button(L10n.Shoot.replacePhoto) {
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
                    Text(L10n.Shoot.addPhoto)
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
            Text(L10n.Shoot.tipsTitle)
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
