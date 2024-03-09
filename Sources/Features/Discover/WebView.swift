//
//  WebView.swift
//
//
//  Created by DeNeRr on 22.02.2024.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
  var html: String
  var hostname: String
  let observer = wkobserver()

  func makeUIView(context: Context) -> WKWebView {
    WKWebsiteDataStore.default().httpCookieStore.add(observer)
    return WKWebView()
  }
  
  func updateUIView(_ webView: WKWebView, context: Context) {
    if let ua = UserDefaults.standard.string(forKey: "userAgent") {
      webView.customUserAgent = ua
    }
    webView.loadHTMLString(html, baseURL: URL(string: hostname))
  }
}

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
