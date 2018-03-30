//
//  NodeModel+NSPasteboardWriting.swift
//  Annay
//
//  Created by Koji Murata on 2018/03/28.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

extension NodeModel: NSPasteboardWriting {
  func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
    if isDirectory { return [.nodeModel] }
    return [.nodeModel, .string]
  }
  
  func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
    switch type {
    case .nodeModel: return id
    case .string:    return body
    default:         return nil
    }
  }
}
