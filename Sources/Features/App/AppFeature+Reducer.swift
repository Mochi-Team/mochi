//
//  AppFeature+Reducer.swift
//
//
//  Created by ErrorErrorError on 4/6/23.
//
//

import Architecture
import ComposableArchitecture
import DatabaseClient
import Discover
import ModuleLists
import Repos
import Settings
import VideoPlayer

extension AppFeature: Reducer {
    public var body: some ReducerOf<Self> {
        Scope(state: \.appDelegate, action: /Action.InternalAction.appDelegate) {
            AppDelegateFeature()
        }

        Reduce { state, action in
            switch action {
            case .view(.didAppear):
                break

            case let .view(.didSelectTab(tab)):
                if state.selected == tab {
                    switch tab {
                    case .discover:
                        if !state.discover.screens.isEmpty {
                            state.discover.screens.removeAll()
                        } else if state.discover.isSearchExpanded {
                            return state.discover.collapseSearch()
                                .map { .internal(.discover($0)) }
                        }
                    case .repos:
                        state.repos.path.removeAll()
                    case .settings:
                        break
                    }
                } else {
                    state.selected = tab
                }

            case .internal(.appDelegate):
                break

            case let .internal(.discover(.delegate(.playbackVideoItem(_, repoModuleID, playlist, group, paging, itemId)))):
                let effect = state.videoPlayer?.clearForNewPlaylistIfNeeded(
                    repoModuleID: repoModuleID,
                    playlist: playlist,
                    group: group,
                    page: paging,
                    episodeId: itemId
                )
                .map { Action.internal(.videoPlayer(.presented($0))) }

                if let effect {
                    return effect
                } else {
                    state.videoPlayer = .init(
                        repoModuleID: repoModuleID,
                        playlist: playlist,
                        contents: .init(),
                        group: group,
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

            case .internal(.videoPlayer):
                break
            }
            return .none
        }
        .ifLet(\.$videoPlayer, action: /Action.InternalAction.videoPlayer) {
            VideoPlayerFeature()
        }

        Scope(state: \.discover, action: /Action.InternalAction.discover) {
            DiscoverFeature()
        }

        Scope(state: \.repos, action: /Action.InternalAction.repos) {
            ReposFeature()
        }

        Scope(state: \.settings, action: /Action.InternalAction.settings) {
            SettingsFeature()
        }
    }
}
