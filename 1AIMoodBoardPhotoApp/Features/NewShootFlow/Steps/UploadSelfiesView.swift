//
//  UploadSelfiesView.swift
//  1AIMoodBoardPhotoApp
//

import SwiftUI

struct UploadSelfiesView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var coordinator: NewShootCoordinator

    @StateObject private var viewModel = UploadSelfiesViewModel()
    @State private var selectedVibe: VibePreset?

    private let tipLines = [
        "No sunglasses or heavy makeup",
        "Face clearly visible",
        "Good, natural lighting",
        "Straight-on or slight angle works best for one photo"
    ]

    private var canContinue: Bool {
        viewModel.hasPhoto && selectedVibe != nil
    }

    private let vibeColumns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                titleBlock

                Text("Photo")
                    .font(.headline)

                photoSlot

                Text("Your vibe:")
                    .font(.headline)

                LazyVGrid(columns: vibeColumns, spacing: 12) {
                    ForEach(VibePreset.allCases) { preset in
                        Button {
                            selectedVibe = preset
                        } label: {
                            Text(preset.rawValue)
                                .font(.subheadline.weight(.medium))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedVibe == preset ? Color.accentColor.opacity(0.18) : Color(.secondarySystemBackground))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(selectedVibe == preset ? Color.accentColor : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Name this shoot (optional)")
                        .font(.subheadline.weight(.medium))
                    TextField("e.g. Summer in Paris", text: $coordinator.shootTitleDraft)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.words)
                }

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
                coordinator.selectedVibe = selectedVibe
                coordinator.push(.processing)
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canContinue)
            .padding()
            .background(.ultraThinMaterial)
        }
        .sheet(isPresented: $viewModel.showPicker) {
            ImagePicker(selectionLimit: 1) { picked in
                viewModel.addImages(picked)
            }
        }
        .onAppear {
            selectedVibe = coordinator.selectedVibe
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 8) {
            Text("Upload photo")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text("of yourself")
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
