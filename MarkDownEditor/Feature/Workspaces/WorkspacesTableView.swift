//
//  WorkspacesTableView.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/25.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class WorkspacesTableView: NSTableView {
  private var moveAction: (() -> Void)!
  
  func prepare(moveAction: @escaping (() -> Void)) {
    self.moveAction = moveAction
  }
  
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
    if clickedRow == -1 || clickedRow >= WorkspaceModel.spaces.value.count { return }

    selectRowIndexes(IndexSet(integer: clickedRow), byExtendingSelection: false)
    let menu = NSMenu()
    menu.addItem(NSMenuItem(title: Localized("Show in Finder"), action: #selector(showInFinder), keyEquivalent: ""))
    menu.addItem(NSMenuItem.separator())
    menu.addItem(NSMenuItem(title: Localized("Delete"), action: #selector(delete), keyEquivalent: ""))
    menu.addItem(NSMenuItem(title: Localized("Move the workspace file"), action: #selector(move), keyEquivalent: ""))
    menu.popUp(positioning: nil, at: location, in: self)
  }
  
  @objc private func delete() {
    if selectedRow == -1 { return }
    WorkspaceModel.spaces.value.remove(at: selectedRow)
  }

  @objc private func move() {
    if selectedRow == -1 { return }
    moveAction()
  }
  
  @objc private func showInFinder() {
    if selectedRow == -1 { return }
    let url = WorkspaceModel.spaces.value[selectedRow].url
    NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
  }
}
