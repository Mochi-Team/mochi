//
//  Architecture.swift
//
//
//  Created by ErrorErrorError on 10/5/23.
//
//

struct Architecture: _Shared {
    var dependencies: any Dependencies {
        FoundationHelpers()
        ComposableArchitecture()
        LocalizableClient()
        LoggerClient()
    }
}
