//
//  JSContext+JSRuntime.swift
//
//
//  Created by ErrorErrorError on 11/4/23.
//
//

import Dependencies
import FileClient
import Foundation
import JavaScriptCore
import JSValueCoder
import SharedModels

extension JSContext {
    convenience init(_ module: Module, _ logger: @escaping (JSMessageLog, String) -> Void) throws {
        self.init()

        setConsoleBinding(logger)
        setRequestBinding()

        @Dependency(\.fileClient)
        var fileClient

        let jsURL = try fileClient.retrieveModuleDirectory(module.mainJSFile)
        try evaluateScript(String(contentsOf: jsURL))
        evaluateScript("const Instance = new source.default()")
    }
}

extension JSContext: JSRuntime {
    func invokeInstanceMethod<T: Decodable>(functionName: String, args: [Encodable]) throws -> T {
        let function = try getFunctionInstance(functionName)

        let encoder = JSValueEncoder()
        let decoder = JSValueDecoder()

        guard let value = try function.call(withArguments: args.map { try encoder.encode($0, into: self) }) else {
            throw ModuleClient.Error.jsRuntime(.instanceCall(function: "Instance.\(functionName)", msg: "Failed to retrieve value from function"))
        }

        return try decoder.decode(T.self, from: value)
    }

    func invokeInstanceMethod(functionName: String, args: [Encodable]) throws {
        let function = try getFunctionInstance(functionName)
        let encoder = JSValueEncoder()
        try function.call(withArguments: args.map { try encoder.encode($0, into: self) })
    }

    func invokeInstanceMethodWithPromise(functionName: String, args: [Encodable]) async throws {
        let function = try getFunctionInstance(functionName)
        let encoder = JSValueEncoder()
        guard let promise = try function.call(withArguments: args.map { try encoder.encode($0, into: self) }) else {
            throw ModuleClient.Error.jsRuntime(.promiseValueError)
        }
        try await promise.value(functionName)
    }

    func invokeInstanceMethodWithPromise<T: Decodable>(functionName: String, args: [Encodable]) async throws -> T {
        let function = try getFunctionInstance(functionName)
        let encoder = JSValueEncoder()
        let decoder = JSValueDecoder()
        guard let promise = try function.call(withArguments: args.map { try encoder.encode($0, into: self) }) else {
            throw ModuleClient.Error.jsRuntime(.instanceCall(function: "Instance.\(functionName)", msg: "Failed to retrieve value from function"))
        }
        return try await decoder.decode(T.self, from: promise.value(functionName))
    }

    private func getInstance() throws -> JSValue {
        guard let instance = evaluateScript("Instance"), !instance.isOptional, instance.isObject else {
            throw ModuleClient.Error.jsRuntime(.retrievingInstanceFailed)
        }
        return instance
    }

    private func getFunctionInstance(_ functionName: String) throws -> JSValue {
        let instance = try getInstance()
        // Function is a form of an object
        guard let function = instance[functionName], function.isObject else {
            throw ModuleClient.Error.jsRuntime(.instanceCall(function: functionName, msg: "this function does not exist"))
        }
        return function
    }
}
