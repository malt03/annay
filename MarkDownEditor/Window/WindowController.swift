//
//  WindowController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/14.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class WindowController: NSWindowController {
  override func windowDidLoad() {
    super.windowDidLoad()
    window?.backgroundColor = NSColor.background
    window?.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
  }
}
