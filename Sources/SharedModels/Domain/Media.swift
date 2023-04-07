//
//  Media.swift
//  
//
//  Created by ErrorErrorError on 4/5/23.
//  
//

import Foundation
import Tagged

struct Media: Identifiable {
    var id: Tagged<Self, String>
    var title: String?
    var metadata: Metadata
}

extension Media {
    enum Metadata {
        case image
        case text
        case video
    }
}

struct Video: Identifiable {
    var id: Tagged<Self, String>
    var title: String
    var thumbnail: URL?
    var sequence: String
}
