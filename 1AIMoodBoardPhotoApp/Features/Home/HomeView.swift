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
    
    private var latestSession: ShootSession? {
        viewModel.sessions.max(by: { $0.createdAt < $1.createdAt })
    }

    var body: some View {
        ZStack {
            Color(.backMain)
                .ignoresSafeArea()
            NavigationStack {
                VStack{
                    //MARK: - Top bar
                    HStack{
                        Text("Aesthetic AI")
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                        
                        Spacer()
                        
                        BananaToolbarTrailing()
                        
                    }.padding(.horizontal)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            if viewModel.sessions.isEmpty {
                                NoShootView(action: {
                                    viewModel.showNewShoot = true
                                })
                                .padding(.top, 48)
                            } else {
                                Text("Latest Shoot")
                                    .font(.title3.bold())
                                if let latestSession {
                                    LatestShootCard(session: latestSession)
                                }

                                Text("My Shots")
                                    .font(.title3.bold())
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(viewModel.sessions, id: \.id) { session in
                                            SessionShotCard(session: session)
                                        }
                                    }
                                }

                                Text("Trending Aesthetics")
                                    .font(.title3.bold())
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(VibePreset.allCases) { vibe in
                                            TrendingAestheticCard(vibe: vibe)
                                        }
                                    }
                                }

                                Button {
                                    viewModel.showNewShoot = true
                                } label: {
                                    CustomButtonView(image: "plus", text: "New Shot")
                                }
                                .padding(.bottom, 70)
                            }
                        }
                        .padding()
                    }
                    .ignoresSafeArea(edges: .bottom)
                }
                .padding(.top)
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
}

private struct LatestShootCard: View {
    let session: ShootSession

    var body: some View {
        HStack(spacing: 14) {
            thumbnail
                .frame(width: 100, height: 132)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                if let title = session.shootTitle, !title.isEmpty {
                    Text(title)
                        .font(.headline)
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

private struct SessionShotCard: View {
    let session: ShootSession

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            thumbnail
                .frame(width: 140, height: 185)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(session.shootTitle?.isEmpty == false ? session.shootTitle! : "Untitled")
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .frame(width: 140, alignment: .leading)
        }
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

private struct TrendingAestheticCard: View {
    let vibe: VibePreset

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if let ui = UIImage(named: vibe.previewAssetName) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .overlay {
                            Image(systemName: vibe.symbolName)
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .frame(width: 140, height: 185)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(vibe.rawValue)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .frame(width: 140, alignment: .leading)
        }
    }
}

#Preview {
    let dependencies = AppDependencies()
    return HomeView()
        .environmentObject(dependencies)
        .modelContainer(dependencies.persistence.container)
}
