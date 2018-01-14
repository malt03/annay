//
//  NodeTableRowView.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/14.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class NodeTableRowView: NSTableRowView {
  override func drawSelection(in dirtyRect: NSRect) {
    NSColor(white: 1, alpha: 0.2).setFill()
    NSBezierPath(rect: bounds).fill()
  }
}
