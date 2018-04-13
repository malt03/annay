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
  private let bag = DisposeBag()
  
  private var finishHandler: (() -> Void)!
  private var firstNavigation = true
  private var hideWhenDragged = false

  private let _isFirstResponder = Variable<Bool>(false)
  var isFirstResponder: Observable<Bool> { return _isFirstResponder.asObservable() }
  var isFirstResponderValue: Bool { return _isFirstResponder.value }
  
  func prepare(hideWhenDragged: Bool, finishHandler: @escaping (() -> Void)) {
    firstNavigation = true
    self.finishHandler = finishHandler

    loadHtmlFile()
    
    navigationDelegate = self
    setValue(false, forKey: "drawsBackground")

    self.hideWhenDragged = hideWhenDragged
    if hideWhenDragged {
      registerForDraggedTypes([.string])
    }
  }
  
  override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
    if hideWhenDragged {
      superview?.isHidden = true
      return []
    }
    return super.draggingEntered(sender)
  }

  private var baseDirectory: URL { return FileManager.default.applicationWeb }
  private var htmlFileUrl: URL { return baseDirectory.appendingPathComponent("index").appendingPathExtension("html") }
  
  private func loadHtmlFile() {
    if FileManager.default.fileExists(atPath: baseDirectory.path) {
      try! FileManager.default.removeItem(at: baseDirectory)
    }

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

    StyleSheetManager.shared.selected.asObservable().subscribe(onNext: { [weak self] (styleSheet) in
      guard let s = self else { return }
      let style: String
      if let styleSheet = styleSheet {
        style = styleSheet.css
      } else {
        style = try! String(contentsOf: Bundle.main.url(forResource: "swiss", withExtension: "css")!)
      }
      let url = Bundle.main.url(forResource: "markdown", withExtension: "html")!
      let styleHighlight = Bundle.main.url(forResource: "monokai-sublime", withExtension: "css")!
      let html = try! String(contentsOf: url)
        .replacingOccurrences(of: "{{style-highlight}}", with: try! String(contentsOf: styleHighlight))
        .replacingOccurrences(of: "{{style}}", with: style)
      try! html.write(to: s.htmlFileUrl, atomically: false, encoding: .utf8)
      s.firstNavigation = true
      s.loadFileURL(s.htmlFileUrl, allowingReadAccessTo: URL(fileURLWithPath: "/"))
    }).disposed(by: bag)
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
  
  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    if window != nil {
      NotificationCenter.default.addObserver(self, selector: #selector(actualSize), name: .ActualSize, object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(zoomIn),     name: .ZoomIn,     object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(zoomOut),    name: .ZoomOut,    object: nil)
    }
  }
  
  override func viewWillMove(toWindow newWindow: NSWindow?) {
    super.viewWillMove(toWindow: newWindow)
    if newWindow == nil {
      NotificationCenter.default.removeObserver(self)
    }
  }
}

extension WebView {
  @objc private func actualSize() {
    evaluateJavaScript("actualSize()", completionHandler: nil)
  }
  
  @objc private func zoomIn() {
    evaluateJavaScript("zoomIn()", completionHandler: nil)
  }
  
  @objc private func zoomOut() {
    evaluateJavaScript("zoomOut()", completionHandler: nil)
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
