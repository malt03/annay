//
//  WorkspacesViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/17.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class WorkspacesViewController: NSViewController {
  @IBOutlet var workspacesController: NSArrayController!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    workspacesController.content = WorkspaceModel.spaces
  }
}

extension WorkspacesViewController: NSTableViewDataSource, NSTableViewDelegate {
  func numberOfRows(in tableView: NSTableView) -> Int {
    return WorkspaceModel.spaces.count
  }
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let workspace = WorkspaceModel.spaces[row]
    let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("WorkspacesTableCellView"), owner: self) as! WorkspacesTableCellView
    cell.prepare(workspace: workspace)
    return cell
  }
}
