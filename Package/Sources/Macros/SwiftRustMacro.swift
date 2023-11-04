//
//  SwiftRustMacro.swift
//
//
//  Created by ErrorErrorError on 10/27/23.
//  
//

struct SwiftRustMacro: _Macro {
    var dependencies: any Dependencies {
        SwiftSyntax()
        SwiftSyntaxMacros()
        SwiftCompilerPlugin()
    }
}
