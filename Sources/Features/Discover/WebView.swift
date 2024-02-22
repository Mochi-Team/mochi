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

  func makeUIView(context: Context) -> WKWebView {
    return WKWebView()
  }
  
  func updateUIView(_ webView: WKWebView, context: Context) {
    let url = URL(string: hostname)!
    WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
      HTTPCookieStorage.shared.setCookies(cookies, for: url, mainDocumentURL: url)
    }
    webView.loadHTMLString(html, baseURL: URL(string: hostname))
  }
}
