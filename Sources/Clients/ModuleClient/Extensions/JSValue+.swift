//
//  JSValue+.swift
//
//
//  Created by ErrorErrorError on 11/17/23.
//
//

import Foundation
import JavaScriptCore

extension JSValue {
  subscript(_ key: String) -> JSValue? {
    guard !isOptional else {
      return nil
    }
    guard let value = forProperty(key) else {
      return nil
    }
    return !value.isOptional ? value : nil
  }

  var isOptional: Bool { isNull || isUndefined }

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

  func toError(_ functionName: String? = nil, stackTrace _: Bool = true) -> JSValueError { .init(self, functionName) }
}

// MARK: - JSValueError

struct JSValueError: Error, LocalizedError, CustomStringConvertible {
  var functionName: String?
  var name: String?
  var errorDescription: String?
  var failureReason: String?
  var stackTrace: String?
  var data: String?
  var status: Double?
  var hostname: String?

  init(_ value: JSValue, _ functionName: String? = nil, stackTrace: Bool = true) {
    self.functionName = functionName
    self.name = value["name"]?.toString()
    self.errorDescription = value["message"]?.toString()
    self.failureReason = value["cause"]?.toString()
    if stackTrace {
      self.stackTrace = value["stack"]?.toString()
    }
    self.data = value["data"]?.toString()
    self.status = value["status"]?.toDouble()
    self.hostname = value["hostname"]?.toString()
  }

  // TODO: Allow stack trace
  var description: String {
    """
    Instance\(functionName.flatMap { ".\($0)" } ?? "") => \
    \(name ?? "Error"): \(errorDescription ?? "No Message") \
    \(failureReason.flatMap { "    \($0)" } ?? "")
    """
  }
}
