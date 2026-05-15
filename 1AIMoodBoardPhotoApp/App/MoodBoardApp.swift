//
//  MoodBoardApp.swift
//  1AIMoodBoardPhotoApp
//

import SwiftUI
import SwiftData
import UIKit
import AppsFlyerLib
import AppTrackingTransparency

@main
struct MoodBoardApp: App {
    @StateObject private var dependencies = AppDependencies()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dependencies)
                .modelContainer(dependencies.persistence.container)
                .environment(\.font, AppFont.custom(17))
                .onAppear {
                    #if DEBUG
                    print("[AppFont] resolved=\(AppFont.resolvedName() ?? "nil")")
                    let playfairNames = UIFont.familyNames
                        .flatMap { UIFont.fontNames(forFamilyName: $0) }
                        .filter { $0.localizedCaseInsensitiveContains("playfair") }
                    print("[AppFont] available playfair names=\(playfairNames)")
                    #endif
                }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    private var didStartAppsFlyer = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        AppsFlyerLib.shared().appsFlyerDevKey = "Xpot5ZNgdk6XZr8CFUqRER"
        AppsFlyerLib.shared().appleAppID = "6766960665"
        #if DEBUG
        AppsFlyerLib.shared().isDebug = true
        #else
        AppsFlyerLib.shared().isDebug = false
        #endif
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        startAppsFlyerAfterATTIfNeeded()
    }

    func application(
        _ application: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        AppsFlyerLib.shared().handleOpen(url, options: options)
        return true
    }

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        AppsFlyerLib.shared().continue(userActivity, restorationHandler: nil)
        return true
    }

    private func startAppsFlyerAfterATTIfNeeded() {
        guard !didStartAppsFlyer else { return }
        if #available(iOS 14, *) {
            switch ATTrackingManager.trackingAuthorizationStatus {
            case .notDetermined:
                ATTrackingManager.requestTrackingAuthorization { _ in
                    DispatchQueue.main.async { [weak self] in
                        self?.startAppsFlyerIfNeeded()
                    }
                }
            case .authorized, .denied, .restricted:
                startAppsFlyerIfNeeded()
            @unknown default:
                startAppsFlyerIfNeeded()
            }
        } else {
            startAppsFlyerIfNeeded()
        }
    }

    private func startAppsFlyerIfNeeded() {
        guard !didStartAppsFlyer else { return }
        didStartAppsFlyer = true
        AppsFlyerLib.shared().start()
    }
}
