//
//  JSContext+Request.swift
//
//
//  Created by ErrorErrorError on 11/17/23.
//
//

import Foundation
import JavaScriptCore

extension JSContext {
  func setRequestBinding() {
    enum RequestError: Error {
      case invalidURL(for: String)
      case invalidResponse(url: URL, method: HTTPMethods)
      case contextUnavailable

      var localizedDescription: String {
        switch self {
        case let .invalidURL(for: string):
          "Invalid URL for \(string)"
        case .contextUnavailable:
          "JSContext is unavailable"
        case let .invalidResponse(url, method):
          "Invalid http response using \(method.httpMethodName) for url: \(url)"
        }
      }
    }

    let request = JSValue(newObjectIn: self)
    let session = URLSession(configuration: .ephemeral)

    enum HTTPMethods: String, CaseIterable {
      case get
      case post
      case put
      case patch

      var httpMethodName: String {
        rawValue.uppercased()
      }
    }

    let buildRequest = { (method: HTTPMethods) in { [weak self] urlString, options in
      guard let self else {
        let error = JSValue(newErrorFromMessage: RequestError.contextUnavailable.localizedDescription, in: JSContext.current())
        return .init(newPromiseRejectedWithReason: error, in: error?.context)
      }

      guard let url = URL(string: urlString) else {
        let error = JSValue(newErrorFromMessage: RequestError.invalidURL(for: urlString).localizedDescription, in: self)
        return .init(newPromiseRejectedWithReason: error, in: self)
      }

      var request = URLRequest(url: url)
      request.httpMethod = method.httpMethodName
      request.httpBody = options["body"]?.toString()?.data(using: .utf8)

      if let timeout = options["timeout"]?.toDouble() {
        request.timeoutInterval = timeout
      }

      if let headers = options["headers"]?.toDictionary() as? [String: String] {
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
      }

      let cookies = HTTPCookieStorage.shared.cookies(for: url).map { $0.map { "\($0.name)=\($0.value)" } }?.joined(separator: "; ")
      request.setValue(cookies, forHTTPHeaderField: "Cookie")

      return .init(newPromiseIn: self) { resolved, rejected in
        let task = session.dataTask(with: request) { data, response, error in
          guard let resolved, let rejected else {
            return
          }

          if let error {
            rejected.call(withArguments: [JSValue(newErrorFromMessage: error.localizedDescription, in: rejected.context) ?? .init()])
          } else {
            guard let response = response as? HTTPURLResponse,
                  let responseObject = JSValue(newObjectIn: resolved.context),
                  let requestObject = JSValue(newObjectIn: resolved.context) else {
              let error = JSValue(
                newErrorFromMessage: RequestError.invalidResponse(url: url, method: method).localizedDescription,
                in: rejected.context
              )
              rejected.call(withArguments: error.flatMap { [$0] })
              return
            }

            // MochiRequestOptions
            requestObject.setObject(url, forKeyedSubscript: "url")
            requestObject.setObject(method.rawValue, forKeyedSubscript: "method")
            requestObject.setObject(options, forKeyedSubscript: "options")

            // MochiResponse
            responseObject.setObject(response.statusCode, forKeyedSubscript: "status")
            responseObject.setObject(HTTPURLResponse.localizedString(forStatusCode: response.statusCode), forKeyedSubscript: "statusText")
            responseObject.setObject(response.allHeaderFields, forKeyedSubscript: "headers")
            responseObject.setObject(requestObject, forKeyedSubscript: "request")

            let data = data ?? .init()
            let dataToText = String(bytes: data, encoding: .utf8) ?? ""
            let dataFunction = {
              let ctx = JSContext.current()
              let buffer = UnsafeMutableRawPointer.allocate(byteCount: data.count, alignment: MemoryLayout<UInt8>.alignment)
              data.copyBytes(to: .init(start: buffer, count: data.count))

              var exception: JSValueRef?

              // swiftlint:disable opening_brace
              guard let bufValue = JSObjectMakeArrayBufferWithBytesNoCopy(
                ctx?.jsGlobalContextRef,
                buffer,
                data.count,
                { buffer, _ in buffer?.deallocate() },
                nil,
                &exception
              ) else {
                return JSValue(object: data, in: self)
              }
              // swiftlint:enable opening_brace

              if let exception {
                return JSValue(jsValueRef: exception, in: ctx)
              } else {
                return JSValue(jsValueRef: bufValue, in: ctx)
              }
            } as @convention(block) () -> JSValue

            let jsonFunction = {
              let ctx = JSContext.current()
              let value = dataToText.withCString(JSStringCreateWithUTF8CString)
              defer { JSStringRelease(value) }
              return JSValue(
                jsValueRef: JSValueMakeFromJSONString(ctx?.jsGlobalContextRef, value) ??
                  JSValueMakeUndefined(ctx?.jsGlobalContextRef),
                in: ctx
              )
            } as @convention(block) () -> JSValue

            let textFunction = {
              let ctx = JSContext.current()
              let value = dataToText.withCString(JSStringCreateWithUTF8CString)
              defer { JSStringRelease(value) }
              return JSValue(jsValueRef: JSValueMakeString(ctx?.jsGlobalContextRef, value), in: ctx)
            } as @convention(block) () -> JSValue

            responseObject.setObject(unsafeBitCast(dataFunction, to: JSValue.self), forKeyedSubscript: "data")
            responseObject.setObject(unsafeBitCast(jsonFunction, to: JSValue.self), forKeyedSubscript: "json")
            responseObject.setObject(unsafeBitCast(textFunction, to: JSValue.self), forKeyedSubscript: "text")

            resolved.call(withArguments: [responseObject])
          }
        }
        task.resume()
      }
    } as @convention(block) (String, JSValue) -> JSValue }

    HTTPMethods.allCases.forEach { method in
      request?.setObject(unsafeBitCast(buildRequest(method), to: JSValue.self), forKeyedSubscript: method.rawValue)
    }
    setObject(request, forKeyedSubscript: "request" as NSString)
  }
}
