//
//  WebView.swift
//
//
//  Created by DeNeRr on 22.02.2024.
//

import SwiftUI
import WebKit

// MARK: - WebView

struct WebView: UIViewRepresentable {
  var html: String
  var hostname: String
  let observer = wkobserver()

  func makeUIView(context _: Context) -> WKWebView {
    WKWebsiteDataStore.default().httpCookieStore.add(observer)
    return WKWebView()
  }

  func updateUIView(_ webView: WKWebView, context _: Context) {
    if let ua = UserDefaults.standard.string(forKey: "userAgent") {
      // NOTE: User Agent seems to be incorrent on a simulator
      webView.customUserAgent = ua
    }
    webView.loadHTMLString(html, baseURL: URL(string: hostname))
  }
}

// MARK: WebView.wkobserver

extension WebView {
  class wkobserver: NSObject, WKHTTPCookieStoreObserver {
    func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
      cookieStore.getAllCookies { cookies in
        let url = URL(string: "http\(cookies[0].isSecure ? "s" : "")://\(cookies[0].domain)")!
        HTTPCookieStorage.shared.setCookies(cookies, for: url, mainDocumentURL: url)
      }
    }
  }
}
