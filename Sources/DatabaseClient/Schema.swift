//
//  MochiSchema.swift
//
//
//  Created by ErrorErrorError on 5/19/23.
//
//

import Foundation
import SharedModels

struct MochiSchema: Schema {
    static var entities: Entities {
        Repo.self
        Module.self
    }
}
