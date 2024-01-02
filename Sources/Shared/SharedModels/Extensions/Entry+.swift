//
//  Entry+.swift
//
//
//  Created by ErrorErrorError on 1/2/24.
//
//

import Foundation
import Tagged

extension Entry {
  public var repoModuleID: RepoModuleID { .init(repoId: repoId, moduleId: moduleId) }
  public var playlistId: Playlist.ID { entryId.coerced(to: Playlist.self) }
}
