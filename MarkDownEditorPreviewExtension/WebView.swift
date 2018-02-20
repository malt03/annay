//
//  WebView.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/20.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import WebKit

final class WebView: WKWebView {
  override var acceptsFirstResponder: Bool { return false }
  override func mouseDown(with event: NSEvent) {}
}
