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
  private var textEditing = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    outlineView.autosaveName = .Sidebar
    outlineView.backgroundColor = .clear
    outlineView.headerView = nil
  }
  
  @IBAction private func secondaryClicked(_ sender: NSClickGestureRecognizer) {
    let location = sender.location(in: outlineView)
    secondaryClickedRow = outlineView.row(at: location)
    if secondaryClickedRow >= 0 {
      if !outlineView.selectedRowIndexes.contains(secondaryClickedRow) {
        outlineView.selectRowIndexes(IndexSet(integer: secondaryClickedRow), byExtendingSelection: false)
      }
    } else {
      outlineView.deselectAll(nil)
    }
    let menu = NSMenu()
    if selectedNode?.isTrash ?? false {
      menu.addItem(NSMenuItem(title: Localized("Empty"), action: #selector(emptyTrash), keyEquivalent: ""))
    } else if selectedNode?.isDeleted ?? false {
      menu.addItem(NSMenuItem(title: Localized("Put Back"), action: #selector(putBackFromTrash), keyEquivalent: ""))
    } else {
      let selected = outlineView.selectedRowIndexes.count > 0
      menu.addItem(NSMenuItem(title: Localized("New Directory"), action: selected ? #selector(createDirectory) : nil, keyEquivalent: ""))
      menu.addItem(NSMenuItem(title: Localized("New Note"), action: selected ? #selector(createNote) : nil, keyEquivalent: "n"))
      menu.addItem(NSMenuItem(title: Localized("New Group"), action: #selector(createGroup), keyEquivalent: ""))
      menu.addItem(NSMenuItem(title: Localized("Delete"), action: selected ? #selector(delete) : nil, keyEquivalent: ""))
    }
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
  
  @objc private func emptyTrash() {
    let alert = NSAlert()
    alert.messageText = Localized("This operation cannot be undone.")
    alert.addButton(withTitle: Localized("Empty"))
    alert.addButton(withTitle: Localized("Cancel"))
    let response = alert.runModal()
    if response == .alertFirstButtonReturn {
      let count = NodeModel.deleted.count
      outlineView.removeItems(at: IndexSet(integersIn: 0..<count), inParent: NodeModel.trash, withAnimation: .effectFade)
      NodeModel.emptyTrash()
    }
  }
  
  @objc private func createDirectory() {
    let insertedNode = NodeModel.createDirectory(parent: selectedParent)
    insert(node: insertedNode, in: selectedParent)
  }
  
  @objc private func createNote() {
    guard let selectedParent = selectedParent else { return }
    let insertedNode = NodeModel.createNote(in: selectedParent)
    insert(node: insertedNode, in: selectedParent)
  }
  
  @objc private func createGroup() {
    NodeModel.createDirectory(name: Localized("New Group"), parent: nil)
    outlineView.reloadData() // アニメーション走らせると表示がバグる
  }
  
  override func keyDown(with event: NSEvent) {
    // ビープ音を消すため
    if event.isPushed(.delete) { return }
    super.keyDown(with: event)
  }
  
  override func keyUp(with event: NSEvent) {
    super.keyUp(with: event)
    
    if !textEditing && event.isPushed(.delete) {
      delete()
    }
  }
  
  @objc private func delete() {
    NSApplication.shared.endEditing()
    let nodes = outlineView.selectedRowIndexes.map { outlineView.item(atRow: $0) as! NodeModel }
    let nodesWithoutChildren = nodes.filter { (node) in
      guard let parent = node.parent else { return true }
      return !nodes.contains(parent)
    }
    let beforeCount = NodeModel.deleted.count
    Realm.transaction { _ in
      for node in nodesWithoutChildren {
        let index = outlineView.childIndex(forItem: node)
        if !node.delete() { continue }
        outlineView.removeItems(at: IndexSet(integer: index), inParent: node.parent, withAnimation: .slideLeft)
      }
    }
    let afterCount = NodeModel.deleted.count
    
    outlineView.expandItem(NodeModel.trash)
    let indexSet = IndexSet(integersIn: beforeCount..<afterCount)
    outlineView.insertItems(at: indexSet, inParent: NodeModel.trash, withAnimation: .slideLeft)
  }
  
  @objc private func putBackFromTrash() {
    let nodes = outlineView.selectedRowIndexes.map { outlineView.item(atRow: $0) as! NodeModel }
    var putBackNodes = [NodeModel]()
    Realm.transaction { _ in
      for node in nodes {
        let beforeIndex = outlineView.childIndex(forItem: node)
        if !node.putBack() { continue }
        putBackNodes.append(node)
        outlineView.removeItems(at: IndexSet(integer: beforeIndex), inParent: NodeModel.trash, withAnimation: .slideLeft)
      }
    }
    for node in putBackNodes {
      guard let index = node.parent?.sortedChildren.index(of: node) else {
        outlineView.reloadData()
        break
      }
      outlineView.insertItems(at: IndexSet(integer: index), inParent: node.parent, withAnimation: .slideLeft)
      for ancestor in node.ancestors.reversed() {
        outlineView.expandItem(ancestor)
      }
    }
    let indexes = IndexSet(putBackNodes.map { outlineView.row(forItem: $0) })
    outlineView.selectRowIndexes(indexes, byExtendingSelection: true)
  }
  
  private func insert(node: NodeModel, in parent: NodeModel?) {
    let index: Int
    if let parent = parent {
      index = parent.sortedChildren.count - 1
    } else {
      index = NodeModel.roots.count - 1
    }
    outlineView.insertItems(at: IndexSet(integer: index), inParent: parent, withAnimation: .effectFade)
    if let parent = parent { outlineView.expandItem(parent) }
    let row = outlineView.row(forItem: node)
    outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
    outlineView.editColumn(0, row: row, with: nil, select: true)
  }
  
  private var selectedParent: NodeModel? {
    guard let selectedNode = selectedNode else { return nil }
    if selectedNode.isDirectory { return selectedNode }
    return selectedNode.parent
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
    guard let node = item as? NodeModel else { return NodeModel.roots.count + 1 }
    return node.sortedChildren.count
  }
  
  func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
    let node = item as! NodeModel
    return node.isDirectory && !node.isDeleted
  }
  
  func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
    guard let node = item as? NodeModel else {
      if index == NodeModel.roots.count { return NodeModel.trash }
      return NodeModel.roots[index]
    }
    return node.sortedChildren[index]
  }

  func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
    let node = item as! NodeModel
    let identifier = NSUserInterfaceItemIdentifier(rawValue: node.isDirectory && !node.isRoot ? "directory" : "note")
    let nodeCell = outlineView.makeView(withIdentifier: identifier, owner: self) as! NodeTableCellView
    nodeCell.prepare(node: node)
    return nodeCell
  }
  
  func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
    return NodeTableRowView()
  }
  
  func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
    let node = item as! NodeModel
    return node.isRoot && !node.isDeleted
  }
}

extension SidebarViewController: NSTextFieldDelegate {
  func control(_ control: NSControl, textShouldBeginEditing fieldEditor: NSText) -> Bool {
    textEditing = true
    return true
  }
  
  func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
    textEditing = false
    return true
  }
}
