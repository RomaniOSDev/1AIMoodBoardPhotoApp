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
    @State private var selectedPhoto: GeneratedPhoto?

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
                        Text(L10n.Home.title)
                            .font(AppFont.custom(40, weight: .bold))
                        
                        Spacer()
                        
                        BananaToolbarTrailing()
                        
                    }.padding(.horizontal)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            if viewModel.sessions.isEmpty {
                                NoShootView(action: {
                                    startNewShootIfPossible()
                                })
                                .padding(.top, 42)
                            } else {
                                Text(L10n.Home.latestShoot)
                                    .font(AppFont.custom(24, weight: .heavy))
                                if let latestSession {
                                    LatestShootCard(session: latestSession)
                                }

                                Button {
                                    startNewShootIfPossible()
                                } label: {
                                    CustomButtonView(image: "plus", text: L10n.Home.newShot)
                                }
                                
                                Text(L10n.Home.myShots)
                                    .font(AppFont.custom(24, weight: .heavy))
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 20) {
                                        ForEach(Array(viewModel.sessions.prefix(3)), id: \.id) { session in
                                            Button {
                                                if let photo = session.newestPhoto {
                                                    selectedPhoto = photo
                                                }
                                            } label: {
                                                SessionShotCard(session: session)
                                            }
                                            .buttonStyle(.plain)
                                            .disabled(session.newestPhoto == nil)
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

                                Text(L10n.Home.trending)
                                    .font(AppFont.custom(24, weight: .heavy))
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 20) {
                                        ForEach(VibePreset.allCases) { vibe in
                                            Button {
                                                startNewShootIfPossible()
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
                    .alert(L10n.Common.error, isPresented: $viewModel.showError) {
                        Button(L10n.Common.ok, role: .cancel) {}
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
            }
        }
    }

    private func startNewShootIfPossible() {
        if dependencies.bananaManager.balance <= 0 {
            NotificationCenter.default.post(name: Notification.Name("showOutOfBananasOverlay"), object: nil)
            return
        }
        viewModel.showNewShoot = true
    }
}

private struct MyShotsMoreCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.pinkApp.opacity(0.28),
                                Color.pinkApp.opacity(0.06),
                                Color(.secondarySystemBackground)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Circle()
                    .fill(Color.pinkApp.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .offset(x: 48, y: -72)
                    .blur(radius: 28)

                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 90, height: 90)
                    .offset(x: -52, y: 64)
                    .blur(radius: 18)

                VStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .frame(width: 72, height: 72)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
                            )
                            .shadow(color: Color.pinkApp.opacity(0.25), radius: 12, x: 0, y: 4)

                        Image(systemName: "photo.stack")
                            .font(.system(size: 30, weight: .medium))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.pinkApp)
                    }

                    VStack(spacing: 3) {
                        Text(L10n.Home.allPhotosCardTitle)
                            .font(AppFont.custom(17, weight: .bold))
                            .foregroundStyle(.primary)
                        Text(L10n.Home.allPhotosCardSubtitle)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .multilineTextAlignment(.center)

                    HStack(spacing: 5) {
                        Text(L10n.Home.allPhotosOpen)
                            .font(.caption.weight(.semibold))
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(Color.pinkApp)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.pinkApp.opacity(0.14))
                            .overlay(
                                Capsule()
                                    .stroke(Color.pinkApp.opacity(0.35), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 8)
            }
            .frame(width: 140, height: 185)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.35),
                                Color.pinkApp.opacity(0.45)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )

            Text(L10n.Home.allPhotosFooter)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.pinkApp)
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
                        .stroke(Color.pinkApp.opacity(0.45), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                .shadow(color: Color.pinkApp.opacity(0.16), radius: 6, x: 0, y: 0)
        )
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
                Text(L10n.Home.sessionPhotoCount(session.generatedCount))
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

            Text(session.shootTitle?.isEmpty == false ? session.shootTitle! : L10n.Home.untitled)
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

            Text(vibe.localizedTitle)
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
