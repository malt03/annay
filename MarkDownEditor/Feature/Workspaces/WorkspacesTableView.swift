//
//  WorkspacesTableView.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/25.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class WorkspacesTableView: NSTableView {
  override func mouseDown(with event: NSEvent) {
    let location = convert(event.locationInWindow, to: nil)
    if event.modifierFlags.contains(.control) {
      rightMouseDown(with: event)
      return
    }
    if row(at: location) == -1 { return }
    super.mouseDown(with: event)
  }
  
  override func rightMouseDown(with event: NSEvent) {
    let location = convert(event.locationInWindow, to: nil)
    let clickedRow = row(at: location)
    if clickedRow == -1 { return }

    selectRowIndexes(IndexSet(integer: clickedRow), byExtendingSelection: false)
    let menu = NSMenu()
    menu.addItem(NSMenuItem(title: Localized("Delete"), action: #selector(delete), keyEquivalent: ""))
    menu.popUp(positioning: nil, at: location, in: self)
  }
  
  @objc private func delete() {
    if selectedRow == -1 { return }
    WorkspaceModel.spaces.value.remove(at: selectedRow)
  }
}
