//
//  NewOrOpenNoteShortcutPreferenceViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/07.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift
import MASShortcut
import RealmSwift

final class NewOrOpenNoteShortcutPreferenceViewController: NSViewController {
  private let bag = DisposeBag()
  private var refreshNodesToken: NotificationToken?
  
  private lazy var selectedWorkspace = Variable(NewOrOpenNoteShortcutManager.shared.workspace(for: kind) ?? WorkspaceModel.selected.value)
  
  @IBOutlet private weak var shortcutView: MASShortcutView!
  @IBOutlet private weak var popUpButton: NSPopUpButton!
  @IBOutlet private weak var outlineView: NSOutlineView!
  @IBOutlet private weak var outlineViewHightConstraint: NSLayoutConstraint!
  
  private var kind: NewOrOpenNoteShortcutManager.Kind!
  
  func prepare(kind: NewOrOpenNoteShortcutManager.Kind) {
    self.kind = kind
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    shortcutView.associatedUserDefaultsKey = NewOrOpenNoteShortcutManager.Key.ShortcutKey(for: kind)
    
    WorkspaceModel.spaces.asObservable().subscribe(onNext: { [weak self] (spaces) in
      guard let s = self else { return }
      s.popUpButton.removeAllItems()
      s.popUpButton.addItems(withTitles: spaces.map { $0.name })
      s.popUpButton.selectItem(at: spaces.index(of: s.selectedWorkspace.value) ?? 0)
    }).disposed(by: bag)
    
    selectedWorkspace.asObservable().subscribe(onNext: { [weak self] (workspace) in
      guard let s = self else { return }
      s.outlineView.autosaveName = nil
      s.outlineView.autosaveName = NSTableView.AutosaveName("NewNoteShortcutPreference/\(workspace.id)")
      s.reloadData()
      
      s.refreshNodesToken?.invalidate()
      s.refreshNodesToken = NodeModel.roots(query: nil, for: workspace).observe { [weak self] _ in self?.reloadData() }
    }).disposed(by: bag)
    
    popUpButton.rx.controlEvent.subscribe(onNext: { [weak self] _ in
      guard let s = self else { return }
      s.selectedWorkspace.value = WorkspaceModel.spaces.value[s.popUpButton.indexOfSelectedItem]
    }).disposed(by: bag)
  }
  
  override func viewDidAppear() {
    super.viewDidAppear()
    selectSelectedDirectory()
    
    // 何故かwindowの初期サイズがおかしい
    outlineViewHightConstraint.priority = .dragThatCannotResizeWindow
  }

  private func reloadData() {
    outlineView.reloadData()
    selectSelectedDirectory()
  }
  
  private func selectSelectedDirectory() {
    let row = outlineView.row(forItem: NewOrOpenNoteShortcutManager.shared.node(for: kind))
    if row > 0 {
      outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
    }
  }
}

extension NewOrOpenNoteShortcutPreferenceViewController: NSOutlineViewDelegate, NSOutlineViewDataSource {
  func outlineView(_ outlineView: NSOutlineView, persistentObjectForItem item: Any?) -> Any? {
    return (item as? NodeModel)?.id
  }
  
  func outlineView(_ outlineView: NSOutlineView, itemForPersistentObject object: Any) -> Any? {
    guard let id = object as? String else { return nil }
    return NodeModel.node(for: id, for: selectedWorkspace.value)
  }
  
  func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
    guard let node = item as? NodeModel else {
      return NodeModel.roots(query: nil, for: selectedWorkspace.value).count
    }
    switch kind! {
    case .new:  return node.sortedDirectoryChildren.count
    case .open: return node.sortedChildren(query: nil).count
    }
  }
  
  func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
    switch kind! {
    case .new:  return true
    case .open: return !(item as! NodeModel).isDirectory
    }
  }
  
  func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
    let node = item as! NodeModel
    switch kind! {
    case .new:  return node.sortedDirectoryChildren.count > 0
    case .open: return node.isDirectory
    }
  }
  
  func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
    guard let node = item as? NodeModel else {
      return NodeModel.roots(query: nil, for: selectedWorkspace.value)[index]
    }
    switch kind! {
    case .new:  return node.sortedDirectoryChildren[index]
    case .open: return node.sortedChildren(query: nil)[index]
    }
    
  }
  
  func outlineViewSelectionDidChange(_ notification: Notification) {
    NewOrOpenNoteShortcutManager.shared.setWorkspace(selectedWorkspace.value, for: kind)
    NewOrOpenNoteShortcutManager.shared.setNode((outlineView.item(atRow: outlineView.selectedRow) as? NodeModel), for: kind)
  }
  
  func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
    let node = item as! NodeModel
    let identifier = NSUserInterfaceItemIdentifier(rawValue: node.isDirectory ? "directory" : "note")
    let nodeCell = outlineView.makeView(withIdentifier: identifier, owner: self) as! NodeTableCellView
    nodeCell.prepare(node: node, inPreference: true)
    return nodeCell
  }
}
