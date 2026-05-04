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
    @State private var showNewShoot = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("My Photos")
                        .font(AppFont.custom(32, weight: .bold))

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
                    VStack(spacing: 14) {
                        Text("You haven't added any photos yet")
                            .font(AppFont.custom(24, weight: .heavy))
                                  Text("Take your first photo")
                                .font(.subheadline)
                        Button {
                            showNewShoot = true
                        } label: {
                            CustomButtonView(image: "plus", text: "Create Shot")
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 28)
                    }
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
                    let repository = dependencies.repository(context: modelContext)
                    PhotoDetailSheet(
                        photo: photo,
                        fileURL: repository.absoluteURL(for: photo),
                        repository: repository,
                        onDeleted: {
                            selectedPhoto = nil
                            viewModel.load()
                        }
                    )
                }
            }
            .fullScreenCover(isPresented: $showNewShoot) {
                NewShootFlowContainer(
                    dependencies: dependencies,
                    onComplete: {
                        showNewShoot = false
                        viewModel.load()
                    }
                )
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
    let repository: ShootRepository
    let onDeleted: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showDeleteConfirmation = false

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
                        .cornerRadius(10)
                        .padding()
                        
                }
                VStack(spacing: 12) {
                    Button {
                        Task { await saveToGallery() }
                    } label: {
                        CustomButtonView(text: "Save to Gallery")
                    }
                    ShareLink(item: fileURL) {
                        CustomButtonView(image: "square.and.arrow.up", text: "Share")
                        
                    }

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        CustomButtonView(image: "trash.fill", text: "Delete Photo")
                            .opacity(0.9)
                    }
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
            .confirmationDialog(
                "Delete this photo?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deletePhoto()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
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

    private func deletePhoto() {
        do {
            try repository.deletePhoto(photo)
            onDeleted()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

private struct MyPhotosPreviewHost: View {
    let dependencies = AppDependencies()

    var body: some View {
        MyPhotosView()
            .environmentObject(dependencies)
            .modelContainer(dependencies.persistence.container)
    }
}

#Preview {
    MyPhotosPreviewHost()
}


