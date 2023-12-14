//
//  JSContext+Console.swift
//
//
//  Created by ErrorErrorError on 11/17/23.
//
//

import Foundation
import JavaScriptCore

extension JSContext {
  func setConsoleBinding(_ logger: @escaping (ModuleLoggerLevel, String) -> Void) {
    exceptionHandler = { _, exception in
      guard let exception else {
        return
      }

      logger(.error, exception.toError().description)
    }

    let console = JSValue(newObjectIn: self)

    let logger = { (type: ModuleLoggerLevel) in {
      guard let arguments = JSContext.currentArguments()?.compactMap({ $0 as? JSValue }) else {
        return
      }

      let msg = arguments.compactMap { $0.toString() }
        .joined(separator: " ")

      logger(type, msg)
    } as @convention(block) () -> Void }

    ModuleLoggerLevel.allCases.forEach { console?.setObject(logger($0), forKeyedSubscript: $0.rawValue) }

    setObject(console, forKeyedSubscript: "console" as NSString)
  }
}
