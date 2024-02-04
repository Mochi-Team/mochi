//
//  CoreDBMacros.swift
//
//
//  Created by ErrorErrorError on 12/28/23.
//
//

struct CoreDBMacros: _Macro {
    var dependencies: any Dependencies {
        SwiftSyntaxMacros()
        SwiftCompilerPlugin()
    }
}
