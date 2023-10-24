//
//  Instance.swift
//
//
//  Created by ErrorErrorError on 4/3/23.
//
//

import CWasm3
import Foundation

// MARK: - WasmInstance

public final class WasmInstance {
    public let exports: Exports
    public let memory: Memory

    private let _environment: IM3Environment
    private let _runtime: IM3Runtime
    private var _module: IM3Module { moduleAndBytes.0 }

    private let moduleAndBytes: (IM3Module, [UInt8])

    private let id: UInt64
    private var idPointer: UnsafeMutableRawPointer

    init(
        module bytes: [UInt8],
        stackSize: UInt32 = 512 * 1_024,
        _ imports: [Import] = []
    ) throws {
        self.id = nextInstanceIdentifier
        self.idPointer = .allocate(
            byteCount: MemoryLayout<UInt64>.size,
            alignment: MemoryLayout<UInt64>.alignment
        )
        idPointer.storeBytes(of: id, as: UInt64.self)

        guard let environment = m3_NewEnvironment() else {
            throw Error.environment(.failedToInitializeEnv)
        }

        guard let runtime = m3_NewRuntime(
            environment,
            stackSize,
            idPointer
        ) else {
            throw Error.runtime(.failedToInitializeRuntime)
        }

        var module: IM3Module?
        try Self.check(m3_ParseModule(environment, &module, bytes, UInt32(bytes.count)))
        guard let module else {
            throw Error.module(.couldNotParseModule)
        }
        try Self.check(m3_LoadModule(runtime, module))

        self._environment = environment
        self._runtime = runtime
        self.moduleAndBytes = (module, bytes)

        self.exports = .init(runtime: _runtime)
        self.memory = .init(runtime: _runtime)

        try importNativeFunctions(imports)
    }

    deinit {
        m3_FreeEnvironment(_environment)
        m3_FreeRuntime(_runtime)
        removeImportedFunctions(forInstanceIdentifier: id)
        idPointer.deallocate()
    }
}

public extension WasmInstance {
    @resultBuilder
    enum ImportsResultBuilder {
        public static func buildEither(first component: [Import]) -> [Import] {
            component
        }

        public static func buildEither(second component: [Import]) -> [Import] {
            component
        }

        public static func buildOptional(_ component: [Import]?) -> [Import] {
            component ?? []
        }

        public static func buildExpression(_ expression: Import) -> [Import] {
            [expression]
        }

        public static func buildExpression(_: ()) -> [Import] {
            []
        }

        public static func buildBlock(_ components: [Import]...) -> [Import] {
            components.flatMap { $0 }
        }

        public static func buildArray(_ components: [[Import]]) -> [Import] {
            Array(components.joined())
        }
    }

    convenience init(
        module: URL,
        stackSize: UInt32 = 512 * 1_024,
        @ImportsResultBuilder _ imports: () -> [Import] = { [] }
    ) throws {
        try self.init(module: [UInt8](Data(contentsOf: module)), stackSize: stackSize, imports())
    }

    convenience init(
        module: [UInt8],
        stackSize: UInt32 = 512 * 1_024,
        @ImportsResultBuilder _ imports: () -> [Import] = { [] }
    ) throws {
        try self.init(module: module, stackSize: stackSize, imports())
    }

    convenience init(
        module: Data,
        stackSize: UInt32 = 512 * 1_024,
        @ImportsResultBuilder _ imports: () -> [Import] = { [] }
    ) throws {
        try self.init(module: .init(module), stackSize: stackSize, imports())
    }

    func importFunctions(
        @ImportsResultBuilder _ imports: () -> [Import] = { [] }
    ) throws {
        try importNativeFunctions(imports())
    }
}

extension WasmInstance {
    private func importNativeFunctions(_ imports: [Import]) throws {
        for `import` in imports {
            let namespace = `import`.namespace
            let functions = `import`.functions
            for function in functions {
                let functionName = function.name
                let functionSignature = function.signature
                let functionHandler = function.handler
                guard let context = UnsafeMutableRawPointer(
                    bitPattern: (namespace + functionName).hashValue
                ) else {
                    throw Error.functions(.couldNotGenerateFunctionContext)
                }

                do {
                    setImportedFunction(functionHandler, for: context, instanceIdentifier: id)
                    try Self.check(
                        m3_LinkRawFunctionEx(
                            _module,
                            namespace,
                            functionName,
                            functionSignature,
                            handleImportedFunction,
                            context
                        )
                    )
                } catch {
                    removeImportedFunction(for: context, instanceIdentifier: id)
                }
            }
        }
    }
}

extension WasmInstance {
    static func check(_ block: @autoclosure () throws -> M3Result?) throws {
        if let result = try block() {
            throw Error.wasm3Error(String(cString: result))
        }
    }
}
