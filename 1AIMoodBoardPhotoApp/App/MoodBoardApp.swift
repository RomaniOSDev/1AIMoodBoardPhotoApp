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

final class AppDelegate: NSObject, UIApplicationDelegate, AppsFlyerLibDelegate { // 🔥 ДОБАВИЛИ AppsFlyerLibDelegate
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        AppsFlyerLib.shared().appsFlyerDevKey = "Xpot5ZNgdk6XZr8CFUqRER"
        AppsFlyerLib.shared().appleAppID = "6766960665"
        AppsFlyerLib.shared().delegate = self  // 🔥 УСТАНОВИЛИ ДЕЛЕГАТ
        
        #if DEBUG
        AppsFlyerLib.shared().isDebug = true
        #endif
        
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // ATT first (when needed), then AppsFlyer — do not call start() in didFinishLaunching.
        AppTrackingCoordinator.requestAuthorizationIfNeeded(delay: 0.6) { status in
            AppsFlyerLib.shared().start()
        }
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
    
    // 🔥 ОБЯЗАТЕЛЬНЫЕ МЕТОДЫ ДЕЛЕГАТА
    
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        print("[AppsFlyer] onConversionDataSuccess: \(data)")
        
        if let status = data["af_status"] as? String {
            switch status {
            case "Non-organic":
                if let source = data["media_source"] as? String,
                   let campaign = data["campaign"] as? String {
                    print("[AppsFlyer] ✅ Non-organic install from: \(source) / \(campaign)")
                }
            case "Organic":
                print("[AppsFlyer] ✅ Organic install")
            default:
                print("[AppsFlyer] Status: \(status)")
            }
        }
        
        // Сохраните conversion data для последующего использования
        if let isFirstLaunch = data["is_first_launch"] as? Bool, isFirstLaunch {
            print("[AppsFlyer] 🎉 First launch detected!")
        }
    }
    
    func onConversionDataFail(_ error: Error) {
        print("[AppsFlyer] ❌ onConversionDataFail: \(error.localizedDescription)")
    }
    
    func onAppOpenAttribution(_ data: [AnyHashable: Any]) {
        print("[AppsFlyer] onAppOpenAttribution: \(data)")
    }
    
    func onAppOpenAttributionFailure(_ error: Error) {
        print("[AppsFlyer] onAppOpenAttributionFailure: \(error.localizedDescription)")
    }
}
