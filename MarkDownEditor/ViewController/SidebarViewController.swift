//
//  SidebarViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/10.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RealmSwift

extension NSTableView.AutosaveName {
  static let Sidebar = NSTableView.AutosaveName("Sidebar")
}

final class SidebarViewController: NSViewController {
  @IBOutlet private weak var outlineView: NSOutlineView!
  
  private var secondaryClickedRow = -1
  
  override func viewDidLoad() {
    super.viewDidLoad()
    outlineView.autosaveName = .Sidebar
  }
  
  @IBAction private func secondaryClicked(_ sender: NSClickGestureRecognizer) {
    let location = sender.location(in: outlineView)
    secondaryClickedRow = outlineView.row(at: location)
    if secondaryClickedRow >= 0 && !outlineView.selectedRowIndexes.contains(secondaryClickedRow) {
      outlineView.selectRowIndexes(IndexSet(integer: secondaryClickedRow), byExtendingSelection: false)
    }
    let menu = NSMenu()
    menu.addItem(NSMenuItem(title: Localized("New Directory"), action: #selector(createDirectory), keyEquivalent: ""))
    menu.addItem(NSMenuItem(title: Localized("New Note"), action: #selector(createNote), keyEquivalent: ""))
    menu.popUp(positioning: nil, at: location, in: outlineView)
  }

  @IBAction private func outlineViewDoubleAction(_ sender: NSOutlineView) {
    guard let clickedItem = outlineView.item(atRow: sender.clickedRow) as? NodeModel else { return }
    if clickedItem.isDirectory {
      if outlineView.isItemExpanded(clickedItem) {
        outlineView.collapseItem(clickedItem)
      } else {
        outlineView.expandItem(clickedItem)
      }
    }
  }

  @objc private func createDirectory() {
    let insertedNode = NodeModel.createDirectory(parent: selectedParent)
    insertInSelectedParent(node: insertedNode)
  }
  
  @objc private func createNote() {
    let insertedNode = NodeModel.createNote(in: selectedParent)
    insertInSelectedParent(node: insertedNode)
  }
  
  private func insertInSelectedParent(node: NodeModel) {
    outlineView.insertItems(at: IndexSet(integer: 0), inParent: selectedParent, withAnimation: .slideDown)
    outlineView.expandItem(selectedParent)
    let row = outlineView.row(forItem: node)
    outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
    outlineView.editColumn(0, row: row, with: nil, select: true)
  }
  
  private var selectedParent: NodeModel {
    guard let selectedNode = selectedNode else { return .root }
    if selectedNode.isDirectory { return selectedNode }
    return selectedNode.parent ?? .root
  }
  
  private var selectedNode: NodeModel? {
    return outlineView.item(atRow: secondaryClickedRow) as? NodeModel
  }
}

extension SidebarViewController: NSGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: NSGestureRecognizer, shouldAttemptToRecognizeWith event: NSEvent) -> Bool {
    return event.modifierFlags.contains(NSEvent.ModifierFlags.control)
  }
}

extension SidebarViewController: NSOutlineViewDataSource, NSOutlineViewDelegate {
  func outlineView(_ outlineView: NSOutlineView, persistentObjectForItem item: Any?) -> Any? {
    return (item as? NodeModel)?.id
  }
  
  func outlineView(_ outlineView: NSOutlineView, itemForPersistentObject object: Any) -> Any? {
    guard let id = object as? String else { return nil }
    return NodeModel.node(for: id)
  }
  
  func outlineViewSelectionDidChange(_ notification: Notification) {
    (outlineView.item(atRow: outlineView.selectedRow) as? NodeModel)?.selected()
  }
  
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
    let identifier = NSUserInterfaceItemIdentifier(rawValue: "node")
    guard let nodeCell = outlineView.makeView(withIdentifier: identifier, owner: self) as? NodeTableCellView else { return nil }
    nodeCell.prepare(node: item as! NodeModel)
    return nodeCell
  }
}
