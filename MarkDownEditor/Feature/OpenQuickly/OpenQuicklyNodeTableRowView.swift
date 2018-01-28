//
//  OpenQuicklyNodeTableRowView.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/28.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class OpenQuicklyNodeTableRowView: NSTableRowView {
  override func drawSelection(in dirtyRect: NSRect) {}
  
  override func draw(_ dirtyRect: NSRect) {
    if isSelected {
      NSColor.selectedRow.setFill()
      dirtyRect.fill()
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
