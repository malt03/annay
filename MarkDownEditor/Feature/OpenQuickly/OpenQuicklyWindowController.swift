//
//  OpenQuicklyWindowController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/28.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class OpenQuicklyWindowController: WindowController {
  override func windowDidLoad() {
    super.windowDidLoad()
    window?.isMovable = false
    window?.center()
  }
}
