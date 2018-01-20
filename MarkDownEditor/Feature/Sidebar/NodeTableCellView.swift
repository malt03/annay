//
//  NodeTableCellView.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/12.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RealmSwift

final class NodeTableCellView: NSTableCellView {
  private var token: NotificationToken?
  
  private var node: NodeModel!
  func prepare(node: NodeModel) {
    self.node = node
    
    textField?.textColor = .text
    textField?.isEditable = node.isDirectory && !node.isDeleted
    textField?.font = NSFont.systemFont(ofSize: 14)
    imageView?.image = NSImage(named: .folder)
    textField?.stringValue = node.name

    observeNode()
  }
  
  private func observeNode() {
    token?.invalidate()
    token = nil
    if node.isTrash { return }
    token = node.observe { [weak self] (change) in
      guard let s = self else { return }
      switch change {
      case .change(let propertyChanges):
        for propertyChange in propertyChanges {
          if propertyChange.name == "name" {
            s.textField?.stringValue = propertyChange.newValue as! String
          }
        }
      default: break
      }
    }
  }
  
  @IBAction private func edited(_ sender: NSTextField) {
    Realm.transaction { _ in
      self.node.name = sender.stringValue
    }
  }
}
