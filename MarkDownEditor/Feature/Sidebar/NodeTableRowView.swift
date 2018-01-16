//
//  NodeTableRowView.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/14.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class NodeTableRowView: NSTableRowView {
  override func drawSelection(in dirtyRect: NSRect) {}
  
  override func draw(_ dirtyRect: NSRect) {
    if isSelected {
      NSColor(white: 1, alpha: 0.3).setFill()
      NSBezierPath(rect: bounds).fill()
    }
  }

  override var selectionHighlightStyle: NSTableView.SelectionHighlightStyle {
    get { return .regular }
    set { }
  }
  
  override var backgroundColor: NSColor {
    get { return .clear }
    set {}
  }
}
