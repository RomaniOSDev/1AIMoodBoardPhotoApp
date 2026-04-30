//
//  MoodBoardApp.swift
//  1AIMoodBoardPhotoApp
//

import SwiftUI
import SwiftData

@main
struct MoodBoardApp: App {
    @StateObject private var dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dependencies)
                .modelContainer(dependencies.persistence.container)
        }
    }
}
