//
//  WebView.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/10.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import WebKit
import RxSwift

final class WebView: WKWebView {
  private var finishHandler: (() -> Void)!
  private var firstNavigation = true

  private let _isFirstResponder = Variable<Bool>(false)
  var isFirstResponder: Observable<Bool> { return _isFirstResponder.asObservable() }
  var isFirstResponderValue: Bool { return _isFirstResponder.value }
  
  func prepare(hideWhenDragged: Bool, finishHandler: @escaping (() -> Void)) {
    firstNavigation = true
    self.finishHandler = finishHandler

    createHtmlFilesIfNeeded()
    loadFileURL(htmlFileUrl, allowingReadAccessTo: URL(fileURLWithPath: "/"))
    
    navigationDelegate = self
    setValue(false, forKey: "drawsBackground")

    if hideWhenDragged {
      registerForDraggedTypes([.string])
    }
  }
  
  override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
    superview?.isHidden = true
    return []
  }

  private var baseDirectory: URL { return FileManager.default.applicationWeb }
  private var htmlFileUrl: URL { return baseDirectory.appendingPathComponent("index").appendingPathExtension("html") }
  
  private func createHtmlFilesIfNeeded() {
    if FileManager.default.fileExists(atPath: baseDirectory.path) { return }
    
    let url = Bundle.main.url(forResource: "markdown", withExtension: "html")!
    let styleHighlight = Bundle.main.url(forResource: "monokai-sublime", withExtension: "css")!
    let style = Bundle.main.url(forResource: "swiss", withExtension: "css")!
    let html = try! String(contentsOfFile: url.path)
      .replacingOccurrences(of: "{{style-highlight}}", with: try! String(contentsOfFile: styleHighlight.path))
      .replacingOccurrences(of: "{{style}}", with: try! String(contentsOfFile: style.path))
    try! FileManager.default.createDirectory(at: baseDirectory, withIntermediateDirectories: true, attributes: nil)
    
    let scriptNames = [
      "highlight.pack.js",
      "jquery.min.js",
      "markdown-it.min.js",
      "markdown-it-task-checkbox.min.js",
      "markdown-it-sub.min.js",
      "markdown-it-sup.min.js",
      "markdown-it-footnote.min.js",
      "markdown-it-emoji.min.js",
      "markdown.js",
    ]
    
    for name in scriptNames {
      try! FileManager.default.copyItem(at: Bundle.main.url(forResource: name, withExtension: nil)!, to: baseDirectory.appendingPathComponent(name))
    }
    
    try! html.write(to: htmlFileUrl, atomically: false, encoding: .utf8)
  }
  
  private var lastMarkdown: String?
  private var lastCompletionHandler: UpdateCompletion?
  
  typealias UpdateCompletion = ((_ html: String) -> Void)
  
  func update(markdown: String, completionHandler: @escaping UpdateCompletion = { _ in }) {
    lastMarkdown = markdown
    lastCompletionHandler = completionHandler
    evaluateJavaScript("update(\"\(markdown)\")", completionHandler: { (html, _) in
      guard let html = html as? String else { return }
      completionHandler(html)
    })
  }
  
  private func updateRetry() {
    guard let lastMarkdown = lastMarkdown, let completionHandler = lastCompletionHandler else { return }
    update(markdown: lastMarkdown, completionHandler: completionHandler)
  }
  
  override func becomeFirstResponder() -> Bool {
    let should = super.becomeFirstResponder()
    if should { _isFirstResponder.value = true }
    return should
  }
  
  override func resignFirstResponder() -> Bool {
    let should = super.resignFirstResponder()
    if should { _isFirstResponder.value = false }
    return should
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
