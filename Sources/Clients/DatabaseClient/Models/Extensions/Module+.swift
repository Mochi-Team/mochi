//
//  Module+.swift
//
//
//  Created by ErrorErrorError on 11/12/23.
//  
//

import Foundation

public extension Module {
    var mainJSFile: URL {
        self.directory.appendingPathComponent("main")
            .appendingPathExtension("js")
    }
}
