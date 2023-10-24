//
//  ManagedObjectID.swift
//
//
//  Created by ErrorErrorError on 9/18/23.
//
//

import CoreData
import Foundation

public struct ManagedObjectID: Hashable, @unchecked Sendable {
    let id: NSManagedObjectID

    init(objectID: NSManagedObjectID) {
        self.id = objectID
    }
}
