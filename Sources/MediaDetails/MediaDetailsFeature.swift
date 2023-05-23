//
//  MediaDetailsFeature.swift
//  
//
//  Created ErrorErrorError on 5/19/23.
//  Copyright © 2023. All rights reserved.
//

import Architecture
import ComposableArchitecture
import DatabaseClient
import ModuleClient
import SharedModels
import SwiftUI
import ViewComponents

public enum MediaDetailsFeature: Feature {
    public struct State: FeatureState {
        public let media: Media
        public var details: Loadable<Media.Details, ModuleClient.Error>
        public var contents: Loadable<[Media.Content], ModuleClient.Error>

        var mediaInfo: Loadable<MediaDetails, ModuleClient.Error> {
            details.mapValue { .init(media: media, details: $0) }
        }

        public init(
            media: Media,
            details: Loadable<Media.Details, ModuleClient.Error> = .pending,
            contents: Loadable<[Media.Content], ModuleClient.Error> = .pending
        ) {
            self.media = media
            self.details = details
            self.contents = contents
        }

        @dynamicMemberLookup
        struct MediaDetails: Equatable {
            let media: Media
            let details: Media.Details

            init(
                media: Media = .init(id: "", meta: .video),
                details: Media.Details = .init()
            ) {
                self.media = media
                self.details = details
            }

            subscript<Value>(dynamicMember dynamicMember: KeyPath<Media, Value>) -> Value {
                media[keyPath: dynamicMember]
            }

            subscript<Value>(dynamicMember dynamicMember: KeyPath<Media.Details, Value>) -> Value {
                details[keyPath: dynamicMember]
            }
        }
    }

    public enum Action: FeatureAction {
        public enum ViewAction: SendableAction {
            case didAppear
            case didTappedBackButton
        }

        public enum DelegateAction: SendableAction {}
        public enum InternalAction: SendableAction {}

        case view(ViewAction)
        case delegate(DelegateAction)
        case `internal`(InternalAction)
    }

    @MainActor
    public struct View: FeatureView {
        public let store: FeatureStoreOf<MediaDetailsFeature>

        @InsetValue(\.tabNavigation)
        var tabNavigationInset

        @SwiftUI.State
        var imageDominatColor: Color?

        nonisolated public init(store: FeatureStoreOf<MediaDetailsFeature>) {
            self.store = store
        }
    }

    public struct Reducer: FeatureReducer {
        public typealias State = MediaDetailsFeature.State
        public typealias Action = MediaDetailsFeature.Action

        public init() {}
    }
}
