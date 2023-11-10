//
//  WKWebView+JSRuntime.swift
//
//
//  Created by ErrorErrorError on 11/4/23.
//
//

// import Foundation
// import JSValueCoder
// import SharedModels
// import WebKit
//
// extension WKWebView: JSRuntime, WKScriptMessageHandler {
//    convenience init(_ module: Module) throws {
//        let config = WKWebViewConfiguration()
//
//        if #available(iOS 14.0, macOS 11.0, *) {
//            config.defaultWebpagePreferences.allowsContentJavaScript = true
//        } else {
//            config.preferences.javaScriptEnabled = true
//        }
//
//        self.init(frame: .zero, configuration: config)
//
//        MessageLog.allCases.forEach { kind in
//            config.userContentController.add(self, name: "_\(kind)Console")
//        }
//
//        try self.evaluateJavaScript(String(contentsOf: module.moduleLocation))
//        self.evaluateJavaScript("const Instance = new source.default()")
//
//        let overriden = MessageLog.allCases.map { "console.\($0.rawValue) = function(args) { window.webkit.messageHandlers._\($0.rawValue)Console(args); };" }
//        self.evaluateJavaScript(overriden.joined(separator: "\n"))
//    }
//
//    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
//        print(message)
//    }
//
//    func invokeInstanceMethod<T>(functionName: String, args: [Encodable]) async throws -> T where T : Decodable {
//        let bruh = Dictionary(uniqueKeysWithValues: args.enumerated().map { ("arg\($0.offset)", $0.element) })
//
//        let value = try await self.callAsyncJavaScript(
//            "Instance.\(functionName)(\(bruh.keys.joined(separator: ","))",
//            arguments: bruh,
//            contentWorld: .defaultClient
//        )
//
//        return unsafeBitCast(value, to: T.self)
//    }
//
//    func invokeInstanceMethod(functionName: String, args: [Encodable]) async throws {
//        let bruh = Dictionary(uniqueKeysWithValues: args.enumerated().map { ("arg\($0.offset)", $0.element) })
//
//        _ = try await self.callAsyncJavaScript(
//            "Instance.\(functionName)(\(bruh.keys.joined(separator: ","))",
//            arguments: bruh,
//            contentWorld: .defaultClient
//        )
//    }
// }
