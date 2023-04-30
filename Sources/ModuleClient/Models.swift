//
//  Models.swift
//  
//
//  Created by ErrorErrorError on 4/10/23.
//  
//

import Foundation
import SharedModels
import Tagged

protocol KVAccess {}

extension KVAccess {
    // TODO: Improve Key-Value access
    // Might be a performance bottleneck, optimize in the future
    subscript(key: String) -> Any? {
        Mirror(reflecting: self)
            .children
            .first { $0.label == key }?
            .value
    }
}
