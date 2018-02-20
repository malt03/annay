//
//  PreviewViewController.swift
//  MarkDownEditorPreviewExtension
//
//  Created by Koji Murata on 2018/02/20.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import Quartz
import WebKit

class PreviewViewController: NSViewController, QLPreviewingController {
  
  override var nibName: NSNib.Name? {
    return NSNib.Name("PreviewViewController")
  }
  
  @IBOutlet private weak var webView: WKWebView!
  @IBOutlet private weak var notFoundLabel: NSTextField!
  
  private var completionHandler: QLPreviewItemLoadingBlock?
  
  func preparePreviewOfSearchableItem(withIdentifier identifier: String, queryString: String, completionHandler handler: @escaping QLPreviewItemLoadingBlock) {
    guard let html = HtmlDataStore.shared.html(for: identifier) else {
      notFoundLabel.isHidden = false
      webView.isHidden = true
      handler(nil)
      return
    }
    notFoundLabel.isHidden = true
    webView.isHidden = false
    completionHandler = handler

    webView.navigationDelegate = self
    webView.loadHTMLString(html, baseURL: nil)
  }
  
}

extension PreviewViewController: WKNavigationDelegate {
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    completionHandler?(nil)
  }
  
  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    completionHandler?(error)
  }
}
