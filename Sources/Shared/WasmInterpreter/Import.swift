//
//  Import.swift
//
//
//  Created by ErrorErrorError on 4/4/23.
//
//

import Foundation

// MARK: - WasmInstance.Import

public extension WasmInstance {
    struct Import {
        let namespace: String
        var functions: [Function] = []

        public init(
            namespace: String,
            _ functions: Function...
        ) {
            self.namespace = namespace
            self.functions = functions
        }
    }
}

public extension WasmInstance.Import {
    @resultBuilder
    enum FunctionsResultBuilder {
        public static func buildBlock(_ components: WasmInstance.Function...) -> [WasmInstance.Function] {
            components
        }

        public static func buildEither(_ component: [WasmInstance.Function]) -> [WasmInstance.Function] {
            component
        }

        public static func buildArray(_ components: [[WasmInstance.Function]]) -> [WasmInstance.Function] {
            components.flatMap { $0 }
        }

        public static func buildOptional(_ component: [WasmInstance.Function]?) -> [WasmInstance.Function] {
            component ?? []
        }
    }

    init(
        namespace: String,
        @FunctionsResultBuilder _ functions: () -> [WasmInstance.Function]
    ) {
        self.namespace = namespace
        self.functions = functions()
    }
}
