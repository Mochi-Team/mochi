//
//  AppDelegate.swift
//  mochi
//
//  Created by ErrorErrorError on 5/19/23.
//
//

import App
import Architecture
import Foundation

#if os(iOS)
import UIKit

let store = Store(
    initialState: AppFeature.State(),
    reducer: { AppFeature.Reducer() }
)

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        store.send(.internal(.appDelegate(.didFinishLaunching)))
        return true
    }

    func application(
        _: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: connectingSceneSession.configuration.name,
            sessionRole: connectingSceneSession.role
        )

        configuration.delegateClass = SceneDelegate.self

        return configuration
    }
}

#else
import AppKit

class AppDelegate: NSObject, UIApplicationDelegate {
    let store = StoreOf<AppFeature.Reducer>(
        initialState: .init(),
        reducer: { AppFeature.Reducer() }
    )

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        store.send(.internal(.appDelegate(.didFinishLaunching)))
        return true
    }

    func applicationShouldTerminate(_: NSApplication) -> NSApplication.TerminateReply {
//        let viewStore = ViewStore(store)
//
//        if viewStore.hasPendingChanges {
//            viewStore.send(.appDelegate(.appWillTerminate))
//            return .terminateLater
//        }
//
        return .terminateNow
    }
}
#endif
