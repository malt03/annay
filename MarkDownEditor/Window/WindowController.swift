//
//  WindowController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/14.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {
  @IBInspectable var backgroundColor: NSColor = .sidebarBackground
  
  override func windowDidLoad() {
    super.windowDidLoad()
    window?.backgroundColor = backgroundColor
    window?.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
  }
}
