//
//  NewWorkspaceShortcutPreferenceViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/07.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift
import MASShortcut
import RealmSwift

final class NewWorkspaceShortcutPreferenceViewController: NSViewController {
  private let bag = DisposeBag()
  private var refreshNodesToken: NotificationToken?
  
  private var selectedWorkspace = Variable(NewWorkspaceShortcutManager.shared.workspace)
  
  @IBOutlet private weak var shortcutView: MASShortcutView!
  @IBOutlet private weak var popUpButton: NSPopUpButton!
  @IBOutlet private weak var outlineView: NSOutlineView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    shortcutView.associatedUserDefaultsKey = NewWorkspaceShortcutManager.Key.ShortcutKey
    
    WorkspaceModel.spaces.asObservable().subscribe(onNext: { [weak self] (spaces) in
      guard let s = self else { return }
      s.popUpButton.removeAllItems()
      s.popUpButton.addItems(withTitles: spaces.map { $0.name })
      s.popUpButton.selectItem(at: spaces.index(of: s.selectedWorkspace.value) ?? 0)
    }).disposed(by: bag)
    
    selectedWorkspace.asObservable().subscribe(onNext: { [weak self] (workspace) in
      guard let s = self else { return }
      s.outlineView.autosaveName = nil
      s.outlineView.autosaveName = NSTableView.AutosaveName("NewWorkspaceShortcutPreference/\(workspace.id)")
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
  }

  private func reloadData() {
    outlineView.reloadData()
    selectSelectedDirectory()
  }
  
  private func selectSelectedDirectory() {
    let row = outlineView.row(forItem: NewWorkspaceShortcutManager.shared.node)
    if row > 0 {
      outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
    }
  }
}

extension NewWorkspaceShortcutPreferenceViewController: NSOutlineViewDelegate, NSOutlineViewDataSource {
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
    return node.sortedDirectoryChildren.count
  }
  
  func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
    let node = item as! NodeModel
    return node.sortedDirectoryChildren.count > 0
  }
  
  func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
    guard let node = item as? NodeModel else {
      return NodeModel.roots(query: nil, for: selectedWorkspace.value)[index]
    }
    return node.sortedDirectoryChildren[index]
  }
  
  func outlineViewSelectionDidChange(_ notification: Notification) {
    NewWorkspaceShortcutManager.shared.workspace = selectedWorkspace.value
    NewWorkspaceShortcutManager.shared.node = outlineView.item(atRow: outlineView.selectedRow) as? NodeModel
  }
  
  func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
    let node = item as! NodeModel
    let identifier = NSUserInterfaceItemIdentifier(rawValue: node.isRoot ? "note" : "directory")
    let nodeCell = outlineView.makeView(withIdentifier: identifier, owner: self) as! NodeTableCellView
    nodeCell.prepare(node: node, inPreference: true)
    return nodeCell
  }
}
