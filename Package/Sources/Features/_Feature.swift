//
//  File.swift
//  
//
//  Created by ErrorErrorError on 10/5/23.
//  
//

import Foundation

protocol Feature: Product, Target {}

extension Feature {
    var path: String? {
        "Sources/Features/\(self.name)"
    }
}
