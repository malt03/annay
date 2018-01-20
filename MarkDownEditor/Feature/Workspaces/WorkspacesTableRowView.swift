//
//  WorkspacesTableRowView.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/20.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

class WorkspacesTableRowView: NSTableRowView {
  override func drawSelection(in dirtyRect: NSRect) {}

  override var isSelected: Bool {
    get { return super.isSelected }
    set {
      super.isSelected = newValue
      alphaValue = newValue ? 1 : 0.3
    }
  }
}
