//
//  SidebarViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/10.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RealmSwift

final class SidebarViewController: NSViewController {
  @IBOutlet private weak var outlineView: NSOutlineView!
  
  @IBAction private func secondaryClicked(_ sender: NSClickGestureRecognizer) {
    let location = sender.location(in: outlineView)
    let row = outlineView.row(at: location)
    if row > 0 {
      outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
    } else {
      outlineView.deselectAll(nil)
    }
    let menu = NSMenu()
    menu.addItem(NSMenuItem(title: Localized("New Directory"), action: #selector(createDirectory), keyEquivalent: ""))
    menu.popUp(positioning: nil, at: location, in: outlineView)
  }

  @objc private func createDirectory() {
    let insertedNode = NodeModel.createDirectory(parent: selectedNode ?? .root)
    outlineView.insertItems(at: IndexSet(integer: 0), inParent: selectedNode, withAnimation: .slideDown)
    if let selectedNode = selectedNode, !outlineView.isItemExpanded(selectedNode) {
      outlineView.expandItem(selectedNode)
    }
    
    outlineView.selectRowIndexes(IndexSet(integer: outlineView.row(forItem: insertedNode)), byExtendingSelection: false)
  }
  
  private var selectedNode: NodeModel? {
    return outlineView.item(atRow: outlineView.selectedRow) as? NodeModel
  }
}

extension SidebarViewController: NSGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: NSGestureRecognizer, shouldAttemptToRecognizeWith event: NSEvent) -> Bool {
    return event.modifierFlags.contains(NSEvent.ModifierFlags.control)
  }
}

extension SidebarViewController: NSOutlineViewDataSource, NSOutlineViewDelegate {
  func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
    guard let node = item as? NodeModel else { return NodeModel.root.sortedChildren.count }
    return node.sortedChildren.count
  }
  
  func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
    return (item as! NodeModel).isDirectory
  }
  
  func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
    guard let node = item as? NodeModel else { return NodeModel.root.sortedChildren[index] }
    return node.sortedChildren[index]
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
