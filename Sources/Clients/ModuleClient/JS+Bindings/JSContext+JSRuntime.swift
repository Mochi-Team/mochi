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
import os
import SharedModels

extension JSContext {
    convenience init( _ module: Module, _ logger: @escaping (MessageLog, String) -> Void) throws {
        self.init()

        addConsoleBinding(logger)
        addRequestBinding()
        try loadModuleAndInitialize(module)
    }

    private func addRequestBinding() {
        enum RequestError: Error {
            case invalidURL(for: String)

            var localizedDescription: String {
                switch self {
                case let .invalidURL(for: string):
                    "Invalid URL for \(string)"
                }
            }
        }

        let request = JSValue(newObjectIn: self)
        let session = URLSession(configuration: .ephemeral)

        let buildRequest: @convention(block) (String, String, JSValue) -> JSValue = { [weak self] urlString, httpMethodString, options in
            guard let `self` = self else {
                let error = JSValue(newErrorFromMessage: "JSContext is unavailable.", in: self)
                return .init(newPromiseRejectedWithReason: error, in: self)
            }

            guard let url = URL(string: urlString) else {
                let error = JSValue(newErrorFromMessage: RequestError.invalidURL(for: urlString).localizedDescription, in: self)
                return .init(newPromiseRejectedWithReason: error, in: self)
            }

            var request = URLRequest(url: url)
            request.httpMethod = httpMethodString.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
            request.httpBody = options["body"]?.toString()?.data(using: .utf8)

            if let timeout = options["timeout"]?.toDouble() {
                request.timeoutInterval = timeout
            }

            if let headers = options["headers"]?.toDictionary() as? [String: String] {
                headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
            }

            return .init(newPromiseIn: self) { resolved, rejected in
                let task = session.dataTask(with: request) { data, response, error in
                    if let error {
                        rejected?.call(withArguments: [JSValue(newErrorFromMessage: error.localizedDescription, in: self) ?? .init()])
                    } else {
                        guard let response = response as? HTTPURLResponse, let responseObject = JSValue(newObjectIn: self) else {
                            let error = JSValue(newErrorFromMessage: "Not a valid http response. url: \(url), method: \(httpMethodString)", in: self)
                            rejected?.call(withArguments: error.flatMap { [$0] })
                            return
                        }

                        let dataToText = data.flatMap { String(bytes: $0, encoding: .utf8) }
                        responseObject.setObject(data, forKeyedSubscript: "data")
                        responseObject.setObject(dataToText, forKeyedSubscript: "dataText")
                        responseObject.setObject(response.url?.absoluteString, forKeyedSubscript: "url")
                        responseObject.setObject(response.allHeaderFields, forKeyedSubscript: "headers")
                        responseObject.setObject(response.statusCode, forKeyedSubscript: "status")
                        responseObject.setObject(HTTPURLResponse.localizedString(forStatusCode: response.statusCode), forKeyedSubscript: "statusText")
                        responseObject.setObject(response.mimeType, forKeyedSubscript: "mimeType")
                        responseObject.setObject(response.expectedContentLength, forKeyedSubscript: "expectedContentLength")
                        responseObject.setObject(response.textEncodingName, forKeyedSubscript: "textEncodingName")
                        resolved?.call(withArguments: [responseObject])
                    }
                }
                task.resume()
            }
        }

        request?.setObject(unsafeBitCast(buildRequest, to: JSValue.self), forKeyedSubscript: "buildRequest")
        setObject(request, forKeyedSubscript: "__request__" as NSString)
    }

    private func addConsoleBinding(_ logger: @escaping (MessageLog, String) -> Void) {
        exceptionHandler = { [weak self] _, exception in
            guard self != nil else {
                return
            }
            let string = exception?.toString() ?? ""
            logger(.error, "js error: \(string)")
        }

        let console = JSValue(newObjectIn: self)

        let logger = { (type: MessageLog) in { [weak self] in
            guard self != nil else {
                return
            }

            guard let arguments = JSContext.currentArguments()?.compactMap({ $0 as? JSValue }) else {
                return
            }

            let msg = arguments.compactMap { $0.toString() }
                .joined(separator: " ")

            logger(type, msg)
        } as @convention(block) () -> Void }

        MessageLog.allCases.forEach { console?.setObject(logger($0), forKeyedSubscript: $0.rawValue) }

        setObject(console, forKeyedSubscript: "console" as NSString)
    }

    private func loadModuleAndInitialize(_ module: Module) throws {
        @Dependency(\.fileClient)
        var fileClient
        let mainModuleURL = module.moduleDirectory.appendingPathComponent("main")
            .appendingPathExtension("js")
        let jsURL = fileClient.retrieveModuleFolder(mainModuleURL)
        try self.evaluateScript(String(contentsOf: jsURL))
        self.evaluateScript("const Instance = new source.default()")
    }
}

extension JSContext: JSRuntime {
    func invokeInstanceMethod<T: Decodable>(functionName: String, args: [Encodable]) throws -> T {
        let function = try getFunctionInstance(functionName)

        let encoder = JSValueEncoder()
        let decoder = JSValueDecoder()

        guard let value = function.call(withArguments: try args.map { try encoder.encode($0, into: self) }) else {
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

        guard let promise = try function.call(withArguments: args.map { try encoder.encode($0, into: self) })else {
            throw ModuleClient.Error.jsRuntime(.promiseValueError)
        }

        try await promise.value(functionName)
    }

    func invokeInstanceMethodWithPromise<T: Decodable>(functionName: String, args: [Encodable]) async throws -> T {
        let function = try getFunctionInstance(functionName)

        let encoder = JSValueEncoder()
        let decoder = JSValueDecoder()

        guard let promise = try function.call(withArguments: args.map { try encoder.encode($0, into: self)}) else {
            throw ModuleClient.Error.jsRuntime(.instanceCall(function: "Instance.\(functionName)", msg: "Failed to retrieve value from function"))
        }

        return try await decoder.decode(T.self, from: promise.value(functionName))
    }

    private func getInstance() throws -> JSValue {
        guard let instance = self.evaluateScript("Instance"), !instance.isOptional, instance.isObject else {
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

private extension JSValue {
    subscript(_ key: String) -> JSValue? {
        guard !isOptional else {
            return nil
        }
        guard let value = self.forProperty(key) else {
            return nil
        }
        return !value.isOptional ? value : nil
    }

    var isOptional: Bool { self.isNull || self.isUndefined }

    @discardableResult
    func value(_ function: String) async throws -> JSValue {
        try await withCheckedThrowingContinuation { continuation in
            let onFufilled: @convention(block) (JSValue) -> Void = { value in
                continuation.resume(returning: value)
            }

            let onRejected: @convention(block) (JSValue) -> Void = { value in
                continuation.resume(throwing: value.toError(function))
            }

            self.invokeMethod(
                "then",
                withArguments: [
                    unsafeBitCast(onFufilled, to: JSValue.self),
                    unsafeBitCast(onRejected, to: JSValue.self)
                ]
            )
        }
    }

    func toError(_ functionName: String) -> JSValueError { .init(self, functionName) }
}

private struct JSValueError: Error, LocalizedError, CustomStringConvertible {
    var functionName: String
    var name: String?
    var errorDescription: String?
    var failureReason: String?

    init(_ value: JSValue, _ functionName: String) {
        self.functionName = functionName
        self.name = value["name"]?.toString()
        self.errorDescription = value["message"]?.toString()
        self.failureReason = value["cause"]?.toString()
    }

    var description: String {
        "Instance.\(functionName) => \(name ?? "Unknown"): \(errorDescription ?? "No Message")" + ((failureReason != nil) ? "\n  \(failureReason ?? "")": "")
    }
}
