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
  override func awakeFromNib() {
    super.awakeFromNib()
    let url = Bundle.main.url(forResource: "markdown", withExtension: "html")!
    loadFileURL(url, allowingReadAccessTo: url)
  }
  
  func update(markdown: String) {
    evaluateJavaScript("update(\"\(markdown)\")", completionHandler: nil)
  }
}
