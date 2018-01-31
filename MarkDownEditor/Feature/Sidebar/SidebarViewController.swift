//
//  SidebarViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/10.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RealmSwift
import RxSwift

extension NSTableView.AutosaveName {
  static var Sidebar: NSTableView.AutosaveName {
    let id = WorkspaceModel.selected.value.id
    return NSTableView.AutosaveName("Sidebar/\(id)")
  }
}

final class SidebarViewController: NSViewController {
  private let bag = DisposeBag()
  private let workspaceNameDisposable = SerialDisposable()
  private let workspaceNameEditDisposable = SerialDisposable()
  
  @IBOutlet private weak var searchFieldHiddenConstraint: NSLayoutConstraint!
  @IBOutlet private weak var searchFieldPresentConstraint: NSLayoutConstraint!
  @IBOutlet private weak var searchField: NSSearchField!
  @IBOutlet private weak var workspaceNameTextField: NSTextField!
  @IBOutlet private weak var outlineView: NSOutlineView!
  
  private let isSearching = Variable<Bool>(false)
  private let queryText = Variable<String?>(nil)
  
  private var secondaryClickedRow = -1
  private var textEditing = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    outlineView.registerForDraggedTypes([.nodeModel, .string])
    outlineView.setDraggingSourceOperationMask([.move, .copy], forLocal: false)
    outlineView.backgroundColor = .clear
    outlineView.headerView = nil
    
    reloadData()
    
    Observable.combineLatest(isSearching.asObservable(), searchField.rx.text) { (isSearching, searchText) -> String? in
      if !isSearching { return nil }
      if searchText == "" { return nil }
      return searchText
    }.bind(to: queryText).disposed(by: bag)
    
    isSearching.asObservable().subscribe(onNext: { [weak self] (isSearching) in
      guard let s = self else { return }
      s.searchFieldPresentConstraint.priority = isSearching ? .defaultHigh : .defaultLow
      s.searchFieldHiddenConstraint.priority = isSearching ? .defaultLow : .defaultHigh
      if isSearching {
        s.view.window?.makeFirstResponder(s.searchField)
      }
    }).disposed(by: bag)
    
    queryText.asObservable().subscribe(onNext: { [weak self] _ in
      self?.outlineView.reloadData()
    }).disposed(by: bag)
    
    NSApplication.shared.endEditing()
  }
  
  override func viewWillAppear() {
    super.viewWillAppear()
    NotificationCenter.default.addObserver(self, selector: #selector(findInWorkspace),                 name: .FindInWorkspace,    object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(createNoteWithoutSecondaryClick), name: .CreateNote,         object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(revealInSidebar),                 name: .RevealInSidebar,    object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(moveFocusToSidebar),              name: .MoveFocusToSidebar, object: nil)
  }
  
  override func viewWillDisappear() {
    NotificationCenter.default.removeObserver(self)
    super.viewWillDisappear()
  }
  
  override func viewDidAppear() {
    super.viewDidAppear()
    NodeModel.selectedNode.asObservable().subscribe(onNext: { [weak self] (node) in
      guard let s = self, let node = node else { return }
      let row = s.outlineView.row(forItem: node)
      if row != -1 && !s.outlineView.selectedRowIndexes.contains(row) {
        s.outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
      }
    }).disposed(by: bag)
  }
  
  @objc private func findInWorkspace() {
    isSearching.value = true
  }
  
  @objc private func revealInSidebar() {
    guard let selected = NodeModel.selectedNode.value else { return }
    for node in selected.ancestors.reversed() {
      outlineView.expandItem(node)
    }
    let row = outlineView.row(forItem: selected)
    if row == -1 { return }
    outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
  }
  
  @objc private func moveFocusToSidebar() {
    view.window?.makeFirstResponder(outlineView)
  }
  
  private func reloadData() {
    WorkspaceModel.selected.asObservable().subscribe(onNext: { [weak self] (workspace) in
      guard let s = self else { return }
      s.workspaceNameDisposable.disposable = workspace.nameObservable.bind(to: s.workspaceNameTextField.rx.text)
      s.workspaceNameEditDisposable.disposable = s.workspaceNameTextField.rx.text.map { $0 ?? "" }.subscribe(onNext: { [weak self] (name) in
        do {
          try workspace.setName(name)
        } catch {
          switch error {
          case MarkDownEditorError.fileExists(oldUrl: let oldUrl):
            self?.workspaceNameTextField.stringValue = oldUrl?.name ?? ""
          default: break
          }
          NSAlert(error: error).runModal()
        }
      })
      s.workspaceNameDisposable.disposed(by: s.bag)
      s.workspaceNameEditDisposable.disposed(by: s.bag)
      
      NodeModel.createFirstDirectoryIfNeeded()
      s.outlineView.autosaveName = .Sidebar
      s.outlineView.reloadData()
    }).disposed(by: bag)
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
  
  @objc private func createNoteWithoutSecondaryClick() {
    secondaryClickedRow = outlineView.selectedRow
    createNote()
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
    let nodes = outlineView.selectedRowIndexes.map { outlineView.item(atRow: $0) as! NodeModel }.removeChildren
    let beforeCount = NodeModel.deleted.count
    Realm.transaction { _ in
      for node in nodes {
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
      guard let index = node.parent?.sortedChildren(query: queryText.value).index(of: node) else {
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
      index = parent.sortedChildren(query: queryText.value).count - 1
    } else {
      index = NodeModel.roots(query: queryText.value).count - 1
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
    guard let node = item as? NodeModel else {
      let rootCount = NodeModel.roots(query: queryText.value).count
      if queryText.value == nil {
        return rootCount + 1
      } else {
        return rootCount
      }
    }
    return node.sortedChildren(query: queryText.value).count
  }
  
  func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
    let node = item as! NodeModel
    return node.isDirectory && !node.isDeleted
  }
  
  func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
    guard let node = item as? NodeModel else {
      if index == NodeModel.roots(query: queryText.value).count { return NodeModel.trash }
      return NodeModel.roots(query: queryText.value)[index]
    }
    return node.sortedChildren(query: queryText.value)[index]
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
  
  func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
    let node = item as! NodeModel
    if node.isTrash { return nil }
    return node
  }
  
  func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
    guard let parentNode = item as? NodeModel else {
      guard let nodes = info.draggingPasteboard().nodes else { return [] }
      let noteContains = nodes.contains(where: { !$0.isDirectory })
      return noteContains ? [] : [.move]
    }
    if parentNode.isDirectory {
      if parentNode.isDeleted { return [] }
    } else {
      return []
    }
    guard let nodes = info.draggingPasteboard().nodes else { return [.move] }
    for node in nodes {
      if node == parentNode { return [] }
      if node.descendants.contains(parentNode) { return [] }
      if node.isDeleted {
        if parentNode.isTrash { return [] }
      } else if node.parent == parentNode {
        let childIndex = outlineView.childIndex(forItem: node)
        if childIndex == index || childIndex + 1 == index { return [] }
      }
    }
    return [.move]
  }
  
  func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
    let parent = item as? NodeModel

    var fixedIndex: Int
    if index < 0 {
      fixedIndex = parent == nil ? NodeModel.roots(query: queryText.value).count : 0
    } else {
      fixedIndex = index
    }
    
    if let ids = info.draggingPasteboard().string(forType: .nodeModel) {
      let movedNodes = ids.split(separator: "\n").flatMap { NodeModel.node(for: String($0)) }.removeChildren
      fixedIndex -= movedNodes.filter { !$0.isDeleted && $0.parent == parent }.map { outlineView.childIndex(forItem: $0) }.filter { $0 < fixedIndex }.count
      
      Realm.transaction { _ in
        if parent == .trash {
          for node in movedNodes {
            node.isDeleted = true
          }
        } else {
          for node in movedNodes { node.index = -1 }
          for (i, child) in (parent?.sortedChildren(query: queryText.value) ?? NodeModel.roots(query: queryText.value)).enumerated() {
            if fixedIndex > i {
              child.index = i
            } else {
              child.index = i + movedNodes.count
            }
          }
          for (i, node) in movedNodes.enumerated() {
            node.index = i + fixedIndex
            node.setParent(parent)
            node.isDeleted = false
          }
        }
      }
      DispatchQueue.main.async { // 謎のクラッシュ解消。多分Realmの反映タイミングとかの問題な気がしている
        outlineView.reloadData()
      }
      return true
    }
    return false
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
  
  func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
    switch commandSelector {
    case #selector(textView.insertNewline(_:)), #selector(textView.cancelOperation(_:)):
      NSApplication.shared.endEditing()
      isSearching.value = false
      return true
    default: return false
    }
  }
}
