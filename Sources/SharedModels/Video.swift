//
//  File.swift
//  
//
//  Created by ErrorErrorError on 4/18/23.
//  
//

import Foundation
import Tagged

public struct Video: Identifiable {
    public var id: Tagged<Self, String>
    public var title: String
    public var thumbnail: URL?
    public var sequence: String
}
