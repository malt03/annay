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
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    if inPreference { return }

    guard let row = superview as? NodeTableRowView else { return }
    row.fillColor.setFill()
    dirtyRect.fill()
  }
  
  private var token: NotificationToken?
  private var node: NodeModel!
  private var inPreference = false
  
  func prepare(node: NodeModel, inPreference: Bool = false) {
    self.node = node
    self.inPreference = inPreference
    
    textField?.textColor = inPreference ? .textColor : .text
    textField?.isEditable = !inPreference && node.isDirectory && !node.isDeleted
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
      alertError { try self.node.setDirectoryName(sender.stringValue) }
    }
  }
}
