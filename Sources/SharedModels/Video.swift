//
//  Playlist+Video.swift
//  
//
//  Created by ErrorErrorError on 4/18/23.
//  
//

import Foundation
import Tagged

public extension Playlist {
    struct EpisodeSource: Sendable, Equatable {
        public let id: String
        public let displayName: String
    }

    struct EpisodeServer: Sendable, Equatable {
        public let name: String
        public let url: String
    }
}
