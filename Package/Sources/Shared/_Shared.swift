//
//  _Shared.swift
//
//
//  Created by ErrorErrorError on 10/5/23.
//
//

import Foundation

// MARK: - _Shared

protocol _Shared: Product, Target {}

extension _Shared {
    var path: String? {
        "Sources/Shared/\(name)"
    }
}
