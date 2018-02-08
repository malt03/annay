//
//  BackgroundSetableView.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/17.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

class BackgroundSetableView: NSView {
  @IBInspectable var cornerRadius: CGFloat = 0
  @IBInspectable var backgroundColor: NSColor? {
    didSet { needsDisplay = true }
  }
  @IBInspectable var borderColor: NSColor?

  override func draw(_ dirtyRect: NSRect) {
    backgroundColor?.setFill()
    borderColor?.setStroke()
    let path = NSBezierPath(roundedRect: dirtyRect, xRadius: cornerRadius, yRadius: cornerRadius)
    path.fill()
    path.stroke()

    super.draw(dirtyRect)
  }
}
