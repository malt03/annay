//
//  BackgroundSetableView.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/17.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class BackgroundSetableView: NSView {
  @IBInspectable var backgroundColor: NSColor?

  override func draw(_ dirtyRect: NSRect) {
    if let backgroundColor = backgroundColor {
      backgroundColor.setFill()
      dirtyRect.fill()
    }
    super.draw(dirtyRect)
  }
}
