//
//  File.swift
//  
//
//  Created by ErrorErrorError on 10/5/23.
//  
//

import Foundation

protocol Shared: Product, Target {}

extension Shared {
    var path: String? {
        "Sources/Shared/\(self.name)"
    }
}
