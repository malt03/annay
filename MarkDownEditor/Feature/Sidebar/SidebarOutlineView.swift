//
//  SidebarOutlineView.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/16.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class SidebarOutlineView: NSOutlineView {
  private var defaultNoteMenu: NSMenu!
  private var deletedNoteMenu: NSMenu!
  private var trashMenu: NSMenu!
  private var backgroundMenu: NSMenu!
  
  private(set) var indexesForMenu: IndexSet?
  private(set) var parentNodeForMenu: NodeModel?
  
  func setMenus(defaultNoteMenu: NSMenu, deletedNoteMenu: NSMenu, trashMenu: NSMenu, backgroundMenu: NSMenu) {
    self.defaultNoteMenu = defaultNoteMenu
    self.deletedNoteMenu = deletedNoteMenu
    self.trashMenu = trashMenu
    self.backgroundMenu = backgroundMenu
  }
  
  override func menu(for event: NSEvent) -> NSMenu? {
    indexesForMenu = nil
    parentNodeForMenu = nil

    let location = convert(event.locationInWindow, from: nil)
    let clickedRow = row(at: location)
    
    if let node = item(atRow: clickedRow) as? NodeModel {
      parentNodeForMenu = node.isDirectory ? node : node.parent
      if selectedRowIndexes.contains(clickedRow) {
        indexesForMenu = selectedRowIndexes
      } else {
        indexesForMenu = IndexSet(integer: clickedRow)
      }
      
      if node.isTrash {
        menu = trashMenu
      } else if node.isDeleted {
        menu = deletedNoteMenu
      } else {
        menu = defaultNoteMenu
      }
    } else {
      menu = backgroundMenu
    }
    return super.menu(for: event)
  }
  
  private var isPreparedReloadData = false
  
  // outlineviewはreloaddataの時にitemを参照してしまうため、realmの削除済みデータを参照してクラッシュする
  func prepareReloadData() -> Bool {
    if isPreparedReloadData { return false }
    defer { isPreparedReloadData = true }
    guard let rootItemCount = dataSource?.outlineView?(self, numberOfChildrenOfItem: nil) else { return false }
    let indexSet = IndexSet(0..<rootItemCount)
    removeItems(at: indexSet, inParent: nil, withAnimation: [])
    return true
  }
  
  override func reloadData() {
    isPreparedReloadData = false
    super.reloadData()
  }
}
