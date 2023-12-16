//
//  MochiApp.swift
//  mochi
//
//  Created by ErrorErrorError on 3/24/23.
//
//

import App
import ComposableArchitecture
import Settings
import SwiftUI
import VideoPlayer

@main
struct MochiApp: App {
  #if canImport(UIKit)
  @UIApplicationDelegateAdaptor(AppDelegate.self)
  #elseif canImport(AppKit)
  @NSApplicationDelegateAdaptor(AppDelegate.self)
  #endif
  var appDelegate

  var body: some Scene {
    WindowGroup {
      #if os(iOS)
      PreferenceHostingView {
        AppFeature.View(
          store: appDelegate.store
        )
      }
      .injectPreference()
      // Ignoring safe area is required for
      // PreferenceHostingView to render outside
      // bounds
      .ignoresSafeArea()
      .themeable()
      #elseif os(macOS)
      AppFeature.View(
        store: appDelegate.store
      )
      .frame(
        minWidth: 800,
        maxWidth: .infinity,
        minHeight: 625,
        maxHeight: .infinity
      )
      .themeable()
      #endif
    }
    #if os(macOS)
    .windowStyle(.titleBar)
    .windowToolbarStyle(.unified)
    .commands {
      SidebarCommands()
      ToolbarCommands()

      CommandGroup(replacing: .newItem) {}
    }
    #endif

    #if os(macOS)
    Settings {
      SettingsFeature.View(
        store: appDelegate.store.scope(
          state: \.settings,
          action: \.internal.settings
        )
      )
      .themeable()
      .frame(width: 412)
    }
    #endif
  }
}
