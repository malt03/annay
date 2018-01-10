//
//  SidebarViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/10.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class SidebarViewController: NSViewController {
}

extension SidebarViewController: NSOutlineViewDataSource, NSOutlineViewDelegate {
  func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
    guard let node = item as? NodeModel else { return NodeModel.root.children.count }
    return node.children.count
  }
  
  func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
    return (item as! NodeModel).isDirectory
  }
  
  func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
    guard let node = item as? NodeModel else { return NodeModel.root.children[index] }
    return node.children[index]
  }

  func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
    let identifier = NSUserInterfaceItemIdentifier(rawValue: "directoryCell")
    guard
      let directoryCell = outlineView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView,
      let textField = directoryCell.textField
      else { return nil }
    textField.stringValue = (item as! NodeModel).name
    textField.sizeToFit()
    return textField
  }
}
