//
//  MyPhotosView.swift
//  1AIMoodBoardPhotoApp
//

import SwiftData
import SwiftUI

struct MyPhotosView: View {
    @EnvironmentObject private var dependencies: AppDependencies
    @Environment(\.modelContext) private var modelContext

    @StateObject private var viewModel = MyPhotosViewModel()
    @State private var selectedPhoto: GeneratedPhoto?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("My Photos")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))

                    Spacer()

                    BananaToolbarTrailing()
                }

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.photos, id: \.id) { photo in
                            PhotoThumbnail(
                                photo: photo,
                                repository: dependencies.repository(context: modelContext)
                            )
                            .onTapGesture {
                                selectedPhoto = photo
                            }
                        }
                    }
                    .padding(12)
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .padding(.horizontal)
            .padding(.top)
            .overlay {
                if viewModel.photos.isEmpty {
                    ContentUnavailableView("No photos yet", systemImage: "photo.on.rectangle.angled")
                }
            }
            .onAppear {
                viewModel.bindRepository(dependencies.repository(context: modelContext))
                viewModel.load()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .sheet(isPresented: Binding(
                get: { selectedPhoto != nil },
                set: { if !$0 { selectedPhoto = nil } }
            )) {
                if let photo = selectedPhoto {
                    PhotoDetailSheet(
                        photo: photo,
                        fileURL: dependencies.repository(context: modelContext).absoluteURL(for: photo)
                    )
                }
            }
        }
    }
}

private struct PhotoThumbnail: View {
    let photo: GeneratedPhoto
    let repository: ShootRepository

    var body: some View {
        let url = repository.absoluteURL(for: photo)
        VStack(alignment: .leading, spacing: 8) {
            if let ui = UIImage(contentsOfFile: url.path) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(3 / 4, contentMode: .fit)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    .aspectRatio(3 / 4, contentMode: .fit)
            }

            Text(photo.session?.shootTitle ?? "Untitled prompt")
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
    }
}

private struct PhotoDetailSheet: View {
    let photo: GeneratedPhoto
    let fileURL: URL

    @Environment(\.dismiss) private var dismiss
    @State private var showError = false
    @State private var errorMessage = ""

    private var image: UIImage? {
        UIImage(contentsOfFile: fileURL.path)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding()
                }
                VStack(spacing: 12) {
                    Button {
                        Task { await saveToGallery() }
                    } label: {
                        Text("Save to Gallery")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    ShareLink(item: fileURL) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationTitle(photo.createdAt.formatted(date: .abbreviated, time: .shortened))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func saveToGallery() async {
        guard let image else { return }
        do {
            let saver = PhotoAlbumSaver()
            try await saver.saveToPhotoLibrary(image)
            print("[PhotoDetail] saved to gallery")
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
