//
//  WorkspacesViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/17.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift

final class WorkspacesViewController: NSViewController {
  private let bag = DisposeBag()
  @IBOutlet private weak var tableView: NSTableView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    WorkspaceModel.spaces.asObservable().subscribe(onNext: { [weak self] _ in
      self?.tableView.reloadData()
    }).disposed(by: bag)
  }
}

extension WorkspacesViewController: NSTableViewDataSource, NSTableViewDelegate {
  func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    if row == WorkspaceModel.spaces.value.count {
      performSegue(withIdentifier: .init(rawValue: "createWorkspace"), sender: nil)
      return false
    }
    return true
  }
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    return WorkspaceModel.spaces.value.count + 1
  }
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    if row == WorkspaceModel.spaces.value.count {
      let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("CreateWorkspacesTableCellView"), owner: self)
      return cell
    }
    let workspace = WorkspaceModel.spaces.value[row]
    let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("WorkspacesTableCellView"), owner: self) as! WorkspacesTableCellView
    cell.prepare(workspace: workspace)
    return cell
  }
}
