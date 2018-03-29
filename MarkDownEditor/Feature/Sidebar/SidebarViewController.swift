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
    let id = WorkspaceModel.selectedValue.id
    return NSTableView.AutosaveName("Sidebar/\(id)")
  }
}

final class SidebarViewController: NSViewController {
  private let bag = DisposeBag()
  private let workspaceNameDisposable = SerialDisposable()
  private let workspaceNameEditDisposable = SerialDisposable()
  private let workspaceEditedDisposable = SerialDisposable()
  private let workspaceUpdatedAtDisposable = SerialDisposable()
  private let workspaceDetectChangeDisposable = SerialDisposable()
  
  @IBOutlet private weak var editedView: BackgroundSetableView!
  @IBOutlet private weak var searchFieldHiddenConstraint: NSLayoutConstraint!
  @IBOutlet private weak var searchFieldPresentConstraint: NSLayoutConstraint!
  @IBOutlet private weak var searchField: NSSearchField!
  @IBOutlet private weak var workspaceNameTextField: NSTextField!
  @IBOutlet private weak var outlineView: SidebarOutlineView!
  @IBOutlet private weak var updatedAtLabel: NSTextField!
  
  @IBOutlet private var defaultNoteMenu: NSMenu!
  @IBOutlet private var deletedNoteMenu: NSMenu!
  @IBOutlet private var trashMenu: NSMenu!
  @IBOutlet private var backgroundMenu: NSMenu!
  
  private let isSearching = Variable<Bool>(false)
  private let queryText = Variable<String?>(nil)
  
  private var textEditing = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    outlineView.registerForDraggedTypes([.nodeModel, .string, .fileURL])
    outlineView.setDraggingSourceOperationMask([.move, .copy], forLocal: false)
    outlineView.backgroundColor = .clear
    outlineView.headerView = nil
    
    outlineView.setMenus(
      defaultNoteMenu: defaultNoteMenu,
      deletedNoteMenu: deletedNoteMenu,
      trashMenu: trashMenu,
      backgroundMenu: backgroundMenu
    )
    
    WorkspaceModel.selectedObservable.subscribe(onNext: { [weak self] (workspace) in
      DispatchQueue.main.async {
        self?.reloadWorkspace(workspace)
      }
    }).disposed(by: bag)
    
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
    
    ShortcutPreference.shared.insertNode.subscribe(onNext: { [weak self] (node) in
      self?.insert(node: node, in: node.parent)
    }).disposed(by: bag)
    
    DispatchQueue.main.async {
      self.moveFocusToSidebar()
    }
  }
  
  override func viewWillAppear() {
    super.viewWillAppear()
    NotificationCenter.default.addObserver(self, selector: #selector(selectNextNote),               name: .SelectNextNote,        object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(selectPreviousNote),           name: .SelectPreviousNote,    object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(findInWorkspace),              name: .FindInWorkspace,       object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(createNoteWithoutMenu),        name: .CreateNote,            object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(createDirectoryWithoutMenu),   name: .CreateDirectory,       object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(createGroupWithoutMenu),       name: .CreateGroup,           object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(revealInSidebar),              name: .RevealInSidebar,       object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(moveFocusToSidebar),           name: .MoveFocusToSidebar,    object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(deleteNote),                   name: .DeleteNote,            object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(deleteNoteImmediately),        name: .DeleteNoteImmediately, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(putBackNote),                  name: .PutBackNote,           object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(emptyTrash),                   name: .EmptyTrash,            object: nil)
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
  
  @objc private func selectNextNote() {
    updateSelectedNode(rowDiff: 1)
  }
  
  @objc private func selectPreviousNote() {
    updateSelectedNode(rowDiff: -1)
  }
  
  private func updateSelectedNode(rowDiff: Int) {
    guard let node = NodeModel.selectedNode.value else { return }
    let row = outlineView.row(forItem: node)
    if row == -1 { return }
    guard let selectRow = searchNoteRow(row: row, diff: rowDiff) else { return }
    outlineView.selectRowIndexes(IndexSet(integer: selectRow), byExtendingSelection: false)
  }
  
  private func searchNoteRow(row: Int, diff: Int) -> Int? {
    var nextRow = row + diff
    guard let nextNode = outlineView.item(atRow: nextRow) as? NodeModel else { return nil }
    if nextNode.isDirectory {
      if !outlineView.isItemExpanded(nextNode) {
        let node = diff < 0 ? outlineView.item(atRow: row) : nil
        outlineView.expandItem(nextNode)
        if let node = node {
          nextRow = outlineView.row(forItem: node)
        }
      }
      return searchNoteRow(row: nextRow, diff: diff)
    }
    return nextRow
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
    moveFocusToSidebar()
  }
  
  @objc private func moveFocusToSidebar() {
    view.window?.makeFirstResponder(outlineView)
  }
  
  override func keyDown(with event: NSEvent) {
    super.keyDown(with: event)
    if event.isPushed(KeyCode.returnKey) {
      moveFocusToEditor()
    }
  }
  
  private func reloadWorkspace(_ workspace: WorkspaceModel) {
    workspaceNameDisposable.disposable = workspace.nameObservable.bind(to: workspaceNameTextField.rx.text)
    workspaceNameEditDisposable.disposable = workspaceNameTextField.rx.text.map { $0 ?? "" }.subscribe(onNext: { [weak self] (name) in
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
    workspaceEditedDisposable.disposable = workspace.savedObservable.bind(to: editedView.rx.isHidden)
    workspaceUpdatedAtDisposable.disposable = workspace.updatedAtObservable.map {
      let formatter = DateFormatter()
      formatter.dateStyle = .short
      formatter.timeStyle = .short
      return formatter.string(from: $0)
    }.bind(to: updatedAtLabel.rx.text)
    workspaceDetectChangeDisposable.disposable = workspace.detectChange.subscribe(onNext: { [weak self] _ in
      guard let s = self else { return }
      let indexes = s.outlineView.selectedRowIndexes
      s.reloadWorkspace(workspace)
      s.outlineView.selectRowIndexes(indexes, byExtendingSelection: false)
    })
    
    workspaceNameDisposable.disposed(by: bag)
    workspaceNameEditDisposable.disposed(by: bag)
    workspaceEditedDisposable.disposed(by: bag)
    workspaceUpdatedAtDisposable.disposed(by: bag)
    workspaceDetectChangeDisposable.disposed(by: bag)
    
    outlineView.autosaveName = nil // 一度変更するとautosaveがきちんと効く。謎だけどワークアラウンド
    outlineView.autosaveName = .Sidebar
    outlineView.reloadData()
  }
  
  @IBAction private func finishSearch(_ sender: NSButton) {
    isSearching.value = false
  }
  
  @IBAction private func outlineViewDoubleAction(_ sender: NSOutlineView) {
    guard let clickedItem = outlineView.item(atRow: sender.clickedRow) as? NodeModel else { return }
    if clickedItem.isDirectory {
      if outlineView.isItemExpanded(clickedItem) {
        outlineView.collapseItem(clickedItem)
      } else {
        outlineView.expandItem(clickedItem)
      }
    } else {
      clickedItem.select()
      moveFocusToEditor()
    }
  }
  
  @IBAction private func emptyTrashWrapper(_ sender: NSMenuItem) {
    emptyTrash()
  }
  
  @IBAction private func exportAsText(_ sender: NSMenuItem) {
    export(type: .text)
  }
  
  @IBAction private func exportAsHtml(_ sender: NSMenuItem) {
    export(type: .html)
  }
  
  private func export(type: NodeModelExporter.ExportType) {
    guard let indexes = outlineView.indexesForMenu else { return }
    let nodes = indexes.map { outlineView.item(atRow: $0) as! NodeModel }.deletingDescendants
    if nodes.count == 0 { return }
    NodeModelExporter(type: type, nodes: nodes).export()
  }
  
  @IBAction private func showInFinder(_ sender: NSMenuItem) {
    guard let indexes = outlineView.indexesForMenu else { return }
    for index in indexes {
      let node = outlineView.item(atRow: index) as! NodeModel
      if node.isTrash { continue }
      NSWorkspace.shared.selectFile(node.url.path, inFileViewerRootedAtPath: node.url.deletingLastPathComponent().path)
    }
  }
  
  @objc private func emptyTrash() {
    let alert = NSAlert()
    alert.messageText = Localized("This operation cannot be undone.")
    alert.addButton(withTitle: Localized("Cancel"))
    alert.addButton(withTitle: Localized("Empty"))
    let response = alert.runModal()
    if response == .alertSecondButtonReturn {
      let count = NodeModel.deleted.count
      outlineView.removeItems(at: IndexSet(integersIn: 0..<count), inParent: NodeModel.trash, withAnimation: .effectFade)
      alertError { try NodeModel.emptyTrash() }
    }
  }
  
  @objc private func createDirectoryWithoutMenu() {
    guard
      let selectedNode = outlineView.item(atRow: outlineView.selectedRow) as? NodeModel,
      let parent = selectedNode.isDirectory ? selectedNode : selectedNode.parent
      else { return }
    createDirectory(parent: parent)
  }
  
  @IBAction private func createDirectory(_ sender: NSMenuItem) {
    guard let parent = outlineView.parentNodeForMenu else { return }
    createDirectory(parent: parent)
  }
  
  private func createDirectory(parent: NodeModel) {
    alertError {
      let insertedNode = try NodeModel.createDirectory(parent: parent)
      insert(node: insertedNode, in: parent)
    }
  }
  
  @objc private func createNoteWithoutMenu() {
    guard
      let selectedNode = outlineView.item(atRow: outlineView.selectedRow) as? NodeModel,
      let parent = selectedNode.isDirectory ? selectedNode : selectedNode.parent
      else { return }
    createNote(parent: parent)
  }
  
  @IBAction private func createNote(_ sender: NSMenuItem) {
    guard let parent = outlineView.parentNodeForMenu else { return }
    createNote(parent: parent)
  }

  private func createNote(parent: NodeModel) {
    let insertedNode = NodeModel.createNote(in: parent)
    insert(node: insertedNode, in: parent)
  }
  
  @IBAction private func createGroup(_ sender: NSMenuItem) {
    createGroupWithoutMenu()
  }
  
  @objc private func createGroupWithoutMenu() {
    alertError {
      let group = try NodeModel.createDirectory(name: Localized("New Group"), parent: nil)
      outlineView.reloadData() // アニメーション走らせると表示がバグる
      let row = outlineView.row(forItem: group)
      if row >= 0 {
        outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        outlineView.editColumn(0, row: row, with: nil, select: true)
      }
    }
  }
  
  private func moveFocusToEditor() {
    NotificationCenter.default.post(name: .MoveFocusToEditor, object: nil)
  }
  
  @objc private func deleteNote() {
    delete(indexes: outlineView.selectedRowIndexes)
  }
  
  @IBAction private func delete(_ sender: NSMenuItem) {
    guard let indexes = outlineView.indexesForMenu else { return }
    delete(indexes: indexes)
  }
  
  private func delete(indexes: IndexSet) {
    outlineView.expandItem(NodeModel.trash)
    let nodes = indexes.map { outlineView.item(atRow: $0) as! NodeModel }.deletingDescendants
    let beforeCount = NodeModel.deleted.count
    Realm.transaction { _ in
      for node in nodes {
        let index = outlineView.childIndex(forItem: node)
        var successDelete = false
        alertError { successDelete = try node.delete() }
        if !successDelete { continue }
        let parent = node.isRoot ? nil : node.parent
        outlineView.removeItems(at: IndexSet(integer: index), inParent: parent, withAnimation: .slideLeft)
      }
    }
    let afterCount = NodeModel.deleted.count
    
    let insertIndexSet = IndexSet(integersIn: beforeCount..<afterCount)
    outlineView.insertItems(at: insertIndexSet, inParent: NodeModel.trash, withAnimation: .slideLeft)
    let trashRow = outlineView.row(forItem: NodeModel.trash)
    var selectIndexSet = IndexSet()
    for insertIndex in insertIndexSet {
      selectIndexSet.insert(trashRow + insertIndex + 1)
    }
    outlineView.selectRowIndexes(selectIndexSet, byExtendingSelection: false)
  }
  
  @objc private func deleteNoteImmediately() {
    deleteImmediately(indexes: outlineView.selectedRowIndexes)
  }
  
  @IBAction private func deleteImmediately(_ sender: NSMenuItem) {
    guard let indexes = outlineView.indexesForMenu else { return }
    deleteImmediately(indexes: indexes)
  }
  
  private func deleteImmediately(indexes: IndexSet) {
    let alert = NSAlert()
    alert.messageText = Localized("This operation cannot be undone.")
    alert.addButton(withTitle: Localized("Cancel"))
    alert.addButton(withTitle: Localized("Delete"))
    let response = alert.runModal()
    if response == .alertSecondButtonReturn {
      let workspace = WorkspaceModel.selectedValue
      Realm.transaction { (realm) in
        let nodes = indexes.map { outlineView.item(atRow: $0) as! NodeModel }.deletingDescendants
        var deletingIndexes = [NodeModel: IndexSet]()
        var deletingIndexForRoot = IndexSet()
        for node in nodes {
          let index = outlineView.childIndex(forItem: node)
          if node.isDeleted || !node.isRoot {
            let parent = node.isDeleted ? NodeModel.trash : node.parent
            if deletingIndexes[parent!] == nil { deletingIndexes[parent!] = IndexSet() }
            deletingIndexes[parent!]?.insert(index)
          } else {
            deletingIndexForRoot.insert(index)
          }
        }
        for (node, index) in deletingIndexes {
          outlineView.removeItems(at: index, inParent: node, withAnimation: .effectFade)
        }
        outlineView.removeItems(at: deletingIndexForRoot, inParent: nil, withAnimation: .effectFade)
        let parents = nodes.compactMap { $0.parent }.uniq
        for node in nodes {
          if node.isInvalidated { continue }
          alertError { try node.deleteImmediately(realm: realm, workspace: workspace) }
        }
        for parent in parents {
          alertError { try parent.save() }
        }
      }
    }
  }
  
  @objc private func putBackNote() {
    putBackFromTrash(indexes: outlineView.selectedRowIndexes)
  }
  
  @IBAction private func putBackFromTrash(_ sender: NSMenuItem) {
    guard let indexes = outlineView.indexesForMenu else { return }
    putBackFromTrash(indexes: indexes)
  }
  
  private func putBackFromTrash(indexes: IndexSet) {
    let nodes = indexes.map { outlineView.item(atRow: $0) as! NodeModel }
    var putBackNodes = [NodeModel]()
    Realm.transaction { _ in
      for node in nodes {
        let beforeIndex = outlineView.childIndex(forItem: node)
        var successPutBack = false
        alertError { successPutBack = try node.putBack() }
        if !successPutBack { continue }
        putBackNodes.append(node)
        outlineView.removeItems(at: IndexSet(integer: beforeIndex), inParent: NodeModel.trash, withAnimation: .slideLeft)
      }
    }
    for node in putBackNodes {
      guard let index = node.parent?.sortedChildren(query: queryText.value).index(of: node) else {
        outlineView.reloadData()
        break
      }
      let parent = node.isRoot ? nil : node.parent
      outlineView.insertItems(at: IndexSet(integer: index), inParent: parent, withAnimation: .slideLeft)
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
    (outlineView.item(atRow: outlineView.selectedRow) as? NodeModel)?.select()
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

  func outlineView(_ outlineView: NSOutlineView, writeItems items: [Any], to pasteboard: NSPasteboard) -> Bool {
    let nodes = items.compactMap { $0 as? NodeModel }.deletingDescendants
    let filePromiseProviders = nodes.map { NSFilePromiseProvider(fileType: kUTTypePlainText as String, delegate: $0) }
    let objects = (nodes as [NSPasteboardWriting]) + (filePromiseProviders as [NSPasteboardWriting])
    pasteboard.writeObjects(objects)
    return true
  }
  
  func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
    let items = info.draggingPasteboard().pasteboardItems ?? []
    let fileURLs = items.compactMap({ URL(string: $0.string(forType: .fileURL) ?? "") })
    if fileURLs.count > 0 {
      let containsCopyable = fileURLs.contains { $0.isDirectory || $0.isConformsToUTI(kUTTypePlainText as String) }
      if !containsCopyable { return [] }
      guard let parentNode = item as? NodeModel else {
        let containsFile = fileURLs.contains { !$0.isDirectory }
        return containsFile ? [] : [.copy]
      }
      if parentNode.isTrash { return [] }
      if parentNode.isDeleted { return [] }
      if !parentNode.isDirectory { return [] }
      return [.copy]
    }
    
    let nodes = info.draggingPasteboard().nodes
    if nodes.count == 0 { return [] }
    
    guard let parentNode = item as? NodeModel else {
      let noteContains = nodes.contains(where: { !$0.isDirectory })
      return noteContains ? [] : [.move]
    }
    if parentNode.isDirectory {
      if parentNode.isDeleted { return [] }
    } else {
      return []
    }
    
    if info.draggingPasteboard().nodes.first?.workspace?.id == WorkspaceModel.selectedValue.id {
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
    } else {
      return parentNode.isTrash ? [] : [.copy]
    }
  }
  
  func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
    defer {
      DispatchQueue.main.async { // 謎のクラッシュ解消。多分Realmの反映タイミングとかの問題な気がしている
        outlineView.reloadData()
      }
    }

    let parent = (item as? NodeModel) ?? NodeModel.root()

    var fixedIndex: Int
    if index < 0 {
      fixedIndex = parent.isRoot ? NodeModel.roots(query: queryText.value).count : 0
    } else {
      fixedIndex = index
    }
    
    let items = info.draggingPasteboard().pasteboardItems ?? []
    let fileURLs = items.compactMap({ URL(string: $0.string(forType: .fileURL) ?? "") })
    if fileURLs.count > 0 {
      do {
        let workspace = WorkspaceModel.selectedValue
        try Realm.transaction { (realm) in
          let creatableCount = fileURLs.creatableRootNodesCount
          for (i, child) in parent.sortedChildren(query: queryText.value).enumerated() {
            if fixedIndex > i {
              child.index = i
            } else {
              child.index = i + creatableCount
            }
          }
          try fileURLs.createNodes(parent: parent, startIndex: fixedIndex, realm: realm, workspace: workspace)
          outlineView.reloadData()
        }
      } catch {
        NSAlert(error: error).runModal()
      }
      return true
    }
    
    let movedNodes = info.draggingPasteboard().nodes
    if movedNodes.count == 0 { return false }
    
    if info.draggingPasteboard().nodes.first?.workspace?.id == WorkspaceModel.selectedValue.id {
      fixedIndex -= movedNodes.filter { !$0.isDeleted && $0.parent == parent }.map { outlineView.childIndex(forItem: $0) }.filter { $0 < fixedIndex }.count
      
      Realm.transaction { _ in
        if parent == .trash {
          for node in movedNodes {
            node.isDeleted = true
          }
        } else {
          for node in movedNodes { node.index = -1 }
          for (i, child) in parent.sortedChildren(query: queryText.value).enumerated() {
            if fixedIndex > i {
              child.index = i
            } else {
              child.index = i + movedNodes.count
            }
          }
          for (i, node) in movedNodes.enumerated() {
            node.index = i + fixedIndex
            alertError { try node.move(in: parent) }
            node.isDeleted = false
          }
        }
      }
    } else {
      Realm.transaction { (realm) in
        let count = movedNodes.count
        for (i, child) in parent.sortedChildren(query: queryText.value).enumerated() {
          if fixedIndex > i {
            child.index = i
          } else {
            child.index = i + count
          }
        }
        for (index, node) in movedNodes.enumerated() {
          alertError { try node.createCopy(realm: realm, parent: parent, index: fixedIndex + index) }
        }
      }
    }
    return true
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
      let selectedRow = outlineView.selectedRow
      view.window?.makeFirstResponder(outlineView)
      if selectedRow >= 0 {
        DispatchQueue.main.async {
          self.outlineView.selectRowIndexes(IndexSet(integer: selectedRow), byExtendingSelection: false)
        }
      }
      isSearching.value = false
      return true
    default: return false
    }
  }
}
