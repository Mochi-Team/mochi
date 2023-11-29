//
//  Logging.swift
//
//
//  Created by ErrorErrorError on 11/27/23.
//  
//

import Foundation
import Logging

struct ModuleLoggerHandler: LogHandler {
    var metadata: Logger.Metadata = .init()
    var logLevel: Logger.Level = .info

    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }
}
