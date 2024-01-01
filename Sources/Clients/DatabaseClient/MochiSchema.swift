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
  }
}
