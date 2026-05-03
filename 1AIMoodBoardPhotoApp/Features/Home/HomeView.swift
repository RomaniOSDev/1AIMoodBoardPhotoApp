//
//  HomeView.swift
//  1AIMoodBoardPhotoApp
//

import SwiftData
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var dependencies: AppDependencies
    @Environment(\.modelContext) private var modelContext
    @Environment(\.mainTabSelection) private var tabSelection

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
                            .font(AppFont.custom(40, weight: .bold))
                        
                        Spacer()
                        
                        BananaToolbarTrailing()
                        
                    }.padding(.horizontal)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            if viewModel.sessions.isEmpty {
                                NoShootView(action: {
                                    viewModel.showNewShoot = true
                                })
                                .padding(.top, 42)
                            } else {
                                Text("Latest Shoot")
                                    .font(AppFont.custom(24, weight: .heavy))
                                if let latestSession {
                                    LatestShootCard(session: latestSession)
                                }

                                Button {
                                    viewModel.showNewShoot = true
                                } label: {
                                    CustomButtonView(image: "plus", text: "New Shot")
                                }
                                
                                Text("My Shots")
                                    .font(AppFont.custom(24, weight: .heavy))
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 20) {
                                        ForEach(Array(viewModel.sessions.prefix(3)), id: \.id) { session in
                                            SessionShotCard(session: session)
                                        }
                                        Button {
                                            tabSelection.wrappedValue = 1
                                        } label: {
                                            MyShotsMoreCard()
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
                                }

                                Text("Trending Aesthetics")
                                    .font(AppFont.custom(24, weight: .heavy))
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 20) {
                                        ForEach(VibePreset.allCases) { vibe in
                                            Button {
                                                viewModel.showNewShoot = true
                                            } label: {
                                                TrendingAestheticCard(vibe: vibe)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
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

private struct MyShotsMoreCard: View {
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.tint)
            }
            .frame(width: 140, height: 185)

            Text("All Photos")
                .font(.caption.weight(.semibold))
                .frame(width: 140, alignment: .leading)
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
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.secondarySystemBackground),
                            Color(.secondarySystemBackground).opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.pinkApp.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                .shadow(color: Color.pinkApp.opacity(0.12), radius: 4, x: 0, y: 0)
        )
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
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.secondarySystemBackground),
                            Color(.secondarySystemBackground).opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.pinkApp.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                .shadow(color: Color.pinkApp.opacity(0.12), radius: 4, x: 0, y: 0)
        )
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
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.secondarySystemBackground),
                            Color(.secondarySystemBackground).opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.pinkApp.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                .shadow(color: Color.pinkApp.opacity(0.12), radius: 4, x: 0, y: 0)
        )
    }
}

#Preview {
    let dependencies = AppDependencies()
    return HomeView()
        .environmentObject(dependencies)
        .modelContainer(dependencies.persistence.container)
}
