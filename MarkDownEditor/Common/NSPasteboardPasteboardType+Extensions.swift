//
//  NSPasteboardPasteboardType+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/15.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

extension NSPasteboard.PasteboardType {
  static let nodeModel = NSPasteboard.PasteboardType("koji.murata.MarkDownEditor.nodeModel")
  static let workspaceModel = NSPasteboard.PasteboardType("koji.murata.MarkDownEditor.workspaceModel")
}
