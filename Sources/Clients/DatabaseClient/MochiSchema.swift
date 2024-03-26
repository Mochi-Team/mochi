//
//  MochiSchema.swift
//
//
//  Created by ErrorErrorError on 12/28/23.
//
//

import CoreDB
import Foundation

struct MochiSchema: Schema {
  static var entities: Entities {
    Repo.self
    Module.self
    PlaylistHistory.self
  }

  enum Migrations: Migratable {
    case version1

    static let current = MochiSchema.Migrations.version1

    func nextVersion() -> Self? {
      switch self {
      case .version1:
        nil
      }
    }
  }
}
