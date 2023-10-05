//
//  Equatable+.swift
//  
//
//  Created by ErrorErrorError on 8/14/23.
//  
//

import Foundation

public extension Equatable {
    var `self`: Self {
        get { self }
        set { self = newValue }
    }
}
