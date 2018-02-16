//
//  WorkspacesTableView.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/25.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class WorkspacesTableView: NSTableView {
  private var defaultMenu: NSMenu!
  
  private(set) var rowForMenu: Int?
  
  func prepare(defaultMenu: NSMenu) {
    self.defaultMenu = defaultMenu
  }
  
  override func menu(for event: NSEvent) -> NSMenu? {
    let location = convert(event.locationInWindow, from: nil)
    let clickedRow = row(at: location)
    if clickedRow == -1 || clickedRow == WorkspaceModel.spaces.value.count {
      menu = nil
      rowForMenu = nil
    } else {
      menu = defaultMenu
      rowForMenu = clickedRow
    }
    return super.menu(for: event)
  }
}
