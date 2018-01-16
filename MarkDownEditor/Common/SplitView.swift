//
//  SplitView.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/16.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class SplitView: NSSplitView {
  override var dividerColor: NSColor {
    get { return .background }
    set {}
  }
}
