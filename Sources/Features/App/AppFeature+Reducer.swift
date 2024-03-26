//
//  AppFeature+Reducer.swift
//
//
//  Created by ErrorErrorError on 4/6/23.
//
//

import Architecture
import ComposableArchitecture
import Darwin
import DatabaseClient
import Discover
import Foundation
import ModuleLists
import Repos
import Settings
import VideoPlayer

extension AppFeature: Reducer {
  public var body: some ReducerOf<Self> {
    Scope(state: \.appDelegate, action: \.internal.appDelegate) {
      AppDelegateFeature()
    }

    Reduce { state, action in
      switch action {
      case .view(.didAppear):
        var sysinfo = utsname()
        uname(&sysinfo)
        let dv = String(bytes: Data(bytes: &sysinfo.release, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
        let dictionary = Bundle(identifier: "com.apple.CFNetwork")?.infoDictionary!
        let cfVersion = dictionary?["CFBundleVersion"] as! String
        if let infoDict = Bundle.main.infoDictionary {
          let version = infoDict["CFBundleVersion"] as! String
          let name = infoDict["CFBundleName"] as! String
          UserDefaults.standard.setValue("\(name)/\(version) CFNetwork/\(cfVersion) Darwin/\(dv)", forKey: "userAgent")
        }

      case let .view(.didSelectTab(tab)):
        if state.selected == tab {
          switch tab {
          case .discover:
            state.discover.path.removeAll()
          case .repos:
            state.repos.path.removeAll()
          case .settings:
            state.settings.path.removeAll()
          }
        } else {
          state.selected = tab
        }

      case .internal(.appDelegate):
        break

      case let .internal(.discover(.delegate(.playbackVideoItem(_, repoModuleId, playlist, group, variant, paging, itemId)))):
        let effect = state.videoPlayer?.clearForNewPlaylistIfNeeded(
          repoModuleId: repoModuleId,
          playlist: playlist,
          groupId: group,
          variantId: variant,
          pageId: paging,
          episodeId: itemId
        )
        .map { Action.internal(.videoPlayer(.presented($0))) }

        if let effect {
          return effect
        } else {
          state.videoPlayer = .init(
            repoModuleId: repoModuleId,
            playlist: playlist,
            group: group,
            variant: variant,
            page: paging,
            episodeId: itemId
          )
        }

      case .internal(.discover):
        break

      case .internal(.repos):
        break

      case .internal(.settings):
        break

      case .internal(.videoPlayer(.dismiss)):
        return .run { send in
          await send(.internal(.discover(.delegate(.playbackDismissed))))
          await playerClient.clear()
        }

      case .internal(.videoPlayer):
        break
      }
      return .none
    }
    .ifLet(\.$videoPlayer, action: \.internal.videoPlayer) {
      VideoPlayerFeature()
    }

    Scope(state: \.discover, action: \.internal.discover) {
      DiscoverFeature()
    }

    Scope(state: \.repos, action: \.internal.repos) {
      ReposFeature()
    }

    Scope(state: \.settings, action: \.internal.settings) {
      SettingsFeature()
    }
  }
}
