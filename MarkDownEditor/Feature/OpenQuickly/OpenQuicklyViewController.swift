//
//  OpenQuicklyViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/28.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift
import RealmSwift

final class OpenQuicklyViewController: NSViewController {
  private let bag = DisposeBag()
  
  private var tableCellHeightCount: CGFloat { return 44 }
  
  @IBOutlet private weak var imageView: NSImageView!
  @IBOutlet private weak var separatorHeightConstraint: NSLayoutConstraint!
  @IBOutlet private weak var tableViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet private weak var searchTextField: OpenQuicklyTextField!
  @IBOutlet private weak var tableView: NSTableView!

  private let result = Variable<Results<NodeModel>>(.empty)
  
  override func viewDidLoad() {
    super.viewDidLoad()
    imageView.image = #imageLiteral(resourceName: "Search").tinted(.text)
    
    searchTextField.rx.text.map { NodeModel.search(query: $0) }.bind(to: result).disposed(by: bag)
    result.asObservable().subscribe(onNext: { [weak self] (result) in
      guard let s = self else { return }
      let resultCount = result.count
      s.separatorHeightConstraint.constant = resultCount == 0 ? 0 : 1
      s.tableViewHeightConstraint.constant = CGFloat(resultCount) * s.tableCellHeightCount
      s.tableView.reloadData()
      if resultCount > 0 {
        s.tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
      }
    }).disposed(by: bag)
  }

  override func mouseMoved(with event: NSEvent) {
    print(event.locationInWindow)
//    let location = tableView.convert(event.locationInWindow, from: nil)
//    let row = tableView.row(at: location)
//    if row == -1 { return }
//    tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
  }
  
  override func mouseDown(with event: NSEvent) {
    print(event.locationInWindow)
  }
}

extension OpenQuicklyViewController: NSTableViewDataSource, NSTableViewDelegate {
  func numberOfRows(in tableView: NSTableView) -> Int {
    return result.value.count
  }
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("OpenQuicklyNodeTableCellView"), owner: self) as! OpenQuicklyNodeTableCellView
    cell.prepare(node: result.value[row])
    return cell
  }
  
  func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
    return OpenQuicklyNodeTableRowView()
  }
}

extension OpenQuicklyViewController: NSTextFieldDelegate {
  func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
    switch commandSelector {
    case #selector(textView.moveUp(_:)):
      if tableView.selectedRow > 0 {
        let index = tableView.selectedRow - 1
        tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        tableView.scrollRowToVisible(index)
      }
      return true
    case #selector(textView.moveDown(_:)):
      if tableView.selectedRow < result.value.count - 1 {
        let index = tableView.selectedRow + 1
        tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        tableView.scrollRowToVisible(index)
      }
      return true
    case #selector(textView.insertNewline(_:)):
      return true
    case #selector(textView.cancelOperation(_:)):
      OpenQuicklyWindowController.hide()
      return true
    default: return false
    }
  }
}
