//
//  File.swift
//  
//
//  Created by ErrorErrorError on 10/27/23.
//  
//

import Foundation

protocol _Macro: Macro {}

extension _Macro {
    var path: String? {
        "Sources/Macros/\(self.name)"
    }
}
