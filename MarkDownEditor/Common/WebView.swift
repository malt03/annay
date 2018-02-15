//
//  WebView.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/10.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import WebKit

final class WebView: WKWebView {
  private var finishHandler: (() -> Void)!
  private var firstNavigation = true
  
  func prepare(finishHandler: @escaping (() -> Void)) {
    firstNavigation = true
    self.finishHandler = finishHandler
    let url = Bundle.main.url(forResource: "markdown", withExtension: "html")!
    loadFileURL(url, allowingReadAccessTo: FileManager.default.homeDirectoryForCurrentUser)
    navigationDelegate = self
    setValue(false, forKey: "drawsBackground")
  }
  
  private var lastMarkdown: String?
  
  func update(markdown: String) {
    lastMarkdown = markdown
    evaluateJavaScript("update(\"\(markdown)\")", completionHandler: nil)
  }
  
  private func updateRetry() {
    guard let lastMarkdown = lastMarkdown else { return }
    update(markdown: lastMarkdown)
  }
}

extension WebView: WKNavigationDelegate {
  func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    switch navigationAction.navigationType {
    case .linkActivated:
      if let url = navigationAction.request.url, let openingUrl = webView.url {
        if url.path == openingUrl.path {
          decisionHandler(.allow)
          return
        }
        NSWorkspace.shared.open(url)
      }
      decisionHandler(.cancel)
    default:
      decisionHandler(.allow)
    }
  }
  
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    if !firstNavigation { return }
    firstNavigation = false
    updateRetry()
    finishHandler()
  }
}
