//
//  NSPasteboardPasteboardType+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/15.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

extension NSPasteboard.PasteboardType {
  static let nodeModel = NSPasteboard.PasteboardType("com.annay.nodeModel")
  static let parentWorkspaceModel = NSPasteboard.PasteboardType("com.annay.parentWorkspaceModel")
  static let workspaceModel = NSPasteboard.PasteboardType("com.annay.workspaceModel")
}
