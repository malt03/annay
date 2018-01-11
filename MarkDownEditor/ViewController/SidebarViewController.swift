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
    outlineView.selectRowIndexes(IndexSet(integer: outlineView.row(at: location)), byExtendingSelection: false)
    let menu = NSMenu()
    menu.addItem(NSMenuItem(title: Localized("New Directory"), action: #selector(createDirectory), keyEquivalent: ""))
    menu.popUp(positioning: nil, at: location, in: outlineView)
  }

  @objc private func createDirectory() {
    NodeModel.createDirectory(parent: selectedNode ?? .root)
  }
  
  private var selectedNode: NodeModel? {
    return outlineView.item(atRow: outlineView.selectedRow) as? NodeModel
  }

  private var nodeModelToken: NotificationToken?

  override func viewWillAppear() {
    super.viewWillAppear()
    nodeModelToken = Realm.instance.objects(NodeModel.self).observe { [weak self] _ in
      self?.outlineView.reloadData()
    }
  }

  override func viewWillDisappear() {
    nodeModelToken?.invalidate()
    super.viewWillDisappear()
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
