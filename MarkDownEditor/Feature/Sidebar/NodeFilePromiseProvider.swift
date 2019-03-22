//
//  NodeFilePromiseProvider.swift
//  Annay
//
//  Created by Koji Murata on 2019/03/22.
//  Copyright © 2019 Koji Murata. All rights reserved.
//

import Cocoa

final class NodeFilePromiseProvider: NSFilePromiseProvider {
  let node: NodeModel
  
  init(node: NodeModel) {
    self.node = node
    super.init()
    fileType = kUTTypePlainText as String
    delegate = node
  }
  
  override func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
    let superTypes = super.writableTypes(for: pasteboard)
    if node.isDirectory { return superTypes + [.nodeModel] }
    return superTypes + [.nodeModel, .string]
  }
  
  override func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
    switch type {
    case .nodeModel: return node.id
    case .string:    return node.body
    default:         return super.pasteboardPropertyList(forType: type)
    }
  }
}
