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

#if canImport(UIKit)
import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
  let store = Store(
    initialState: .init(),
    reducer: { AppFeature() }
  )

  func application(
    _: UIApplication,
    didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    store.send(.internal(.appDelegate(.didFinishLaunching)))
    UserDefaults.standard.register(defaults: [
        "userSettings.fastForwardAmount": 15,
        "userSettings.fastBackwardAmount": 5
        ])
    return true
  }
}

#elseif canImport(AppKit)
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
  let store = Store(
    initialState: .init(),
    reducer: { AppFeature() }
  )

  func applicationDidFinishLaunching(_: Notification) {
    store.send(.internal(.appDelegate(.didFinishLaunching)))
  }

  func applicationShouldTerminate(_: NSApplication) -> NSApplication.TerminateReply {
    .terminateNow
  }
}
#endif
