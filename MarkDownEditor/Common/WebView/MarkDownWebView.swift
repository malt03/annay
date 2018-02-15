//
//  MarkDownWebView.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/15.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import WebKit

final class MarkDownWebView: WebView {
  override var fileName: String { return "markdown" }
  
  private var lastMarkdown: String?
  
  func update(markdown: String) {
    lastMarkdown = markdown
    evaluateJavaScript("update(\"\(markdown)\")", completionHandler: nil)
  }
  
  private func updateRetry() {
    guard let lastMarkdown = lastMarkdown else { return }
    update(markdown: lastMarkdown)
  }

  override func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    if firstNavigation { updateRetry() }
    super.webView(webView, didFinish: navigation)
  }
}
