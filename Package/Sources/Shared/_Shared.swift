//
//  Shared.swift
//  
//
//  Created by ErrorErrorError on 10/5/23.
//  
//

import Foundation

protocol _Shared: Product, Target {}

extension _Shared {
    var path: String? {
        "Sources/Shared/\(self.name)"
    }
}
