//
//  Live.swift
//  
//
//  Created ErrorErrorError on 4/8/23.
//  Copyright © 2023. All rights reserved.
//

import Dependencies
import Foundation

extension DatabaseClient: DependencyKey {
    public static let liveValue = Self()
}
