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
  @IBOutlet private weak var tableView: WorkspacesTableView!
  
  private var createOrOpenWorkspaceSegment = CreateOrOpenWorkspaceTabViewController.Segment.create
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.prepare(moveAction: { [weak self] in
      self?.performSegue(withIdentifier: .init(rawValue: "moveWorkspace"), sender: nil)
    })
    
    tableView.registerForDraggedTypes([.workspaceModel])
    tableView.setDraggingSourceOperationMask([.move], forLocal: true)
    
    WorkspaceModel.spaces.asObservable().subscribe(onNext: { [weak self] _ in
      self?.tableView.reloadData()
      DispatchQueue.main.async {
        self?.tableView.selectRowIndexes(IndexSet(integer: WorkspaceModel.selectedIndex), byExtendingSelection: false)
      }
    }).disposed(by: bag)
  }
  
  override func viewWillAppear() {
    super.viewWillAppear()
    NotificationCenter.default.addObserver(self, selector: #selector(moveFocusToWorkspaces), name: .MoveFocusToWorkspaces, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(openWorkspace), name: .OpenWorkspace, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(createWorkspace), name: .CreateWorkspace, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(selectNextWorkspace), name: .SelectNextWorkspace, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(selectPreviousWorkspace), name: .SelectPreviousWorkspace, object: nil)
  }
  
  override func viewWillDisappear() {
    super.viewWillDisappear()
    NotificationCenter.default.removeObserver(self)
  }
  
  @objc private func moveFocusToWorkspaces() {
    view.window?.makeFirstResponder(tableView)
  }
  
  @objc private func openWorkspace() {
    createOrOpenWorkspaceSegment = .open
    createOrOpenWorkspace()
  }
  
  @objc private func createWorkspace() {
    createOrOpenWorkspaceSegment = .create
    createOrOpenWorkspace()
  }
  
  private func createOrOpenWorkspace() {
    performSegue(withIdentifier: NSStoryboardSegue.Identifier(rawValue: "createOrOpenWorkspace"), sender: nil)
  }
  
  @objc private func selectNextWorkspace() {
    let row = tableView.selectedRow == WorkspaceModel.spaces.value.count - 1 ? 0 : tableView.selectedRow + 1
    tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
  }
  
  @objc private func selectPreviousWorkspace() {
    let row = tableView.selectedRow == 0 ? WorkspaceModel.spaces.value.count - 1 : tableView.selectedRow - 1
    tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
  }
  
  override func viewDidAppear() {
    super.viewDidAppear()

    WorkspaceModel.selected.asObservable().subscribe(onNext: { [weak self] _ in
      guard let s = self else { return }
      if s.tableView.selectedRow == WorkspaceModel.selectedIndex { return }
      self?.tableView.selectRowIndexes(IndexSet(integer: WorkspaceModel.selectedIndex), byExtendingSelection: false)
    }).disposed(by: bag)
  }
  
  override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
    switch segue.destinationController {
    case let wc as WindowController:
      switch wc.contentViewController {
      case let vc as MoveWorkspaceViewController:
        vc.prepare(workspace: WorkspaceModel.spaces.value[tableView.selectedRow])
      case let vc as CreateOrOpenWorkspaceTabViewController:
        vc.prepare(segment: createOrOpenWorkspaceSegment)
      default: break
      }
    default: break
    }
    super.prepare(for: segue, sender: sender)
  }
}

extension WorkspacesViewController: NSTableViewDataSource, NSTableViewDelegate {
  func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    if row == WorkspaceModel.spaces.value.count {
      createWorkspace()
      return false
    }
    return true
  }
  
  func tableViewSelectionDidChange(_ notification: Notification) {
    WorkspaceModel.spaces.value[safe: tableView.selectedRow]?.select()
  }
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    return WorkspaceModel.spaces.value.count + 1
  }
  
  func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
    return WorkspacesTableRowView()
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
  
  func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
    if row == WorkspaceModel.spaces.value.count { return nil }
    let item = NSPasteboardItem()
    item.setString("\(row)", forType: .workspaceModel)
    return item
  }
  
  func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
    if dropOperation == .on { return [] }
    guard let draggingRow = Int(info.draggingPasteboard().string(forType: .workspaceModel) ?? "") else { return [] }
    if draggingRow == row || draggingRow == row - 1 { return [] }
    if row == WorkspaceModel.spaces.value.count + 1 { return [] }
    return [.move]
  }
  
  func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
    guard let draggingRow = Int(info.draggingPasteboard().string(forType: .workspaceModel) ?? "") else { return false }
    WorkspaceModel.move(from: draggingRow, to: row)
    return true
  }
}
