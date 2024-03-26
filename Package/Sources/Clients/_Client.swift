//
//  _Client.swift
//
//
//  Created by ErrorErrorError on 10/5/23.
//
//

import Foundation

// MARK: - _Client

protocol _Client: Product, Target {}

extension _Client {
    var path: String? {
        "Sources/Clients/\(name)"
    }
}
