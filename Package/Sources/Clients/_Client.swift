//
//  File.swift
//  
//
//  Created by ErrorErrorError on 10/5/23.
//  
//

import Foundation

protocol Client: Target {}

extension Client {
    var path: String? {
        "Sources/Clients/\(self.name)"
    }
}
