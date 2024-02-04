//
//  _Feature.swift
//
//
//  Created by ErrorErrorError on 10/5/23.
//
//

import Foundation

// MARK: - _Feature

protocol _Feature: Product, Target {}

extension _Feature {
    var path: String? {
        "Sources/Features/\(name)"
    }
}
