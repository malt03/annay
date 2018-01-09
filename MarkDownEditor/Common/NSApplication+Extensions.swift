//
//  NSApplication+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/10.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

extension NSApplication {
  func endEditing() {
    keyWindow?.makeFirstResponder(nil)
  }
}
