//
//  _Client.swift
//  
//
//  Created by ErrorErrorError on 10/5/23.
//  
//

import Foundation

protocol _Client: Product, Target {}

extension _Client {
    var path: String? {
        "Sources/Clients/\(self.name)"
    }
}
