//
//  SceneDelegate.swift
//  mochi
//
//  Created by ErrorErrorError on 6/27/23.
//
//

#if os(iOS)
import App
import ComposableArchitecture
import Foundation
import UIKit
import UserSettingsClient

final class SceneDelegate: NSObject, UISceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo _: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) {
        window = (scene as? UIWindowScene).flatMap { UIWindow(windowScene: $0) }
        window?.rootViewController = HostingController(rootView: AppFeature.View(store: store).themable())
        window?.makeKeyAndVisible()
    }
}
#endif
