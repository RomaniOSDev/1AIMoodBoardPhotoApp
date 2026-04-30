//
//  HomeView.swift
//  1AIMoodBoardPhotoApp
//

import SwiftData
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var dependencies: AppDependencies
    @Environment(\.modelContext) private var modelContext

    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            VStack{
                //MARK: - Top bar
                HStack{
                    Text("Aesthetic AI")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                    
                    Spacer()
    
                    BananaToolbarTrailing()
                    
                }
            ScrollView {
                VStack(spacing: 16) {
                    
                    //MARK: - Latest Shoot
                    
                    
                    //MARK: - My Shots
                    ForEach(viewModel.sessions, id: \.id) { session in
                        SessionRow(session: session)
                    }
                    
                    //MARK: - No shoot
                    if viewModel.sessions.isEmpty {
                        NoShootView(action: {
                            viewModel.showNewShoot = true
                        })
                        .padding(.top, 48)
                    }
                    
                    //MARK: - Trending Aesthetics
                    
                    
                }
                
            }
        }.padding()
//            .safeAreaInset(edge: .bottom) {
//                Button {
//                    viewModel.showNewShoot = true
//                } label: {
//                    Text("New Shoot")
//                        .font(.headline)
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                }
//                .buttonStyle(.borderedProminent)
//                .padding()
//                .background(.ultraThinMaterial)
//            }
            .onAppear {
                viewModel.bindRepository(dependencies.repository(context: modelContext))
                viewModel.load()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .fullScreenCover(isPresented: $viewModel.showNewShoot) {
                NewShootFlowContainer(
                    dependencies: dependencies,
                    onComplete: {
                        viewModel.showNewShoot = false
                        viewModel.load()
                    }
                )
            }
        }
    }
}

private struct SessionRow: View {
    let session: ShootSession

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                if let title = session.shootTitle, !title.isEmpty {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                }
                Text(session.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                Text("\(session.generatedCount) photo(s)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
    }

    @ViewBuilder private var thumbnail: some View {
        if let path = session.thumbnailRelativePath {
            let url = documentsDirectory().appendingPathComponent(path)
            if let ui = UIImage(contentsOfFile: url.path) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Color.gray.opacity(0.3)
            .overlay {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
    }

    private func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}
