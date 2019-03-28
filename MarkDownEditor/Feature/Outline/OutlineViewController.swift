//
//  OutlineViewController.swift
//  Annay
//
//  Created by Koji Murata on 2019/03/28.
//  Copyright © 2019 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift
import RealmSwift

extension NSTableView.AutosaveName {
  static var Outline: NSTableView.AutosaveName {
    let id = NodeModel.selectedNode.value?.id ?? ""
    return "Outline/\(id)"
  }
}

final class OutlineViewController: NSViewController {
  private let bag = DisposeBag()
  
  @IBOutlet private weak var outlineView: NSOutlineView!
  
  private var outlines = [OutlineModel]()
  private var outlineDictionary = [String: OutlineModel]()
  private var lastUpdateItem: DispatchWorkItem?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let nodeChanged = NodeModel.selectedNode.asObservable().distinctUntilChanged()
    nodeChanged.subscribe(onNext: { [weak self] (node) in
      guard let s = self, let node = node else { return }
      DispatchQueue.global(qos: .utility).async(execute: s.createUpdateItem(body: node.body))
    }).disposed(by: bag)
    nodeChanged.flatMap { (node) -> Observable<String> in
      guard let node = node else { return Observable.never() }
      return Observable.from(object: node, properties: ["body"]).map { $0.body }.skip(0)
    }.subscribe(onNext: { [weak self] (body) in
      guard let s = self else { return }
      s.lastUpdateItem?.cancel()
      let updateItem = s.createUpdateItem(body: body)
      s.lastUpdateItem = updateItem
      DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.2, execute: updateItem)
    }).disposed(by: bag)
  }
  
  private func createUpdateItem(body: String) -> DispatchWorkItem {
    return DispatchWorkItem { [weak self] in
      guard let s = self else { return }
      (s.outlines, s.outlineDictionary) = OutlineModel.create(from: body)
      DispatchQueue.main.async {
        s.outlineView.autosaveName = nil // 一度変更するとautosaveがきちんと効く。謎だけどワークアラウンド
        s.outlineView.autosaveName = .Outline
        s.outlineView.reloadData()
      }
    }
  }
  
  override func mouseDown(with event: NSEvent) {
    super.mouseDown(with: event)
    let location = outlineView.convert(event.locationInWindow, from: nil)
    let row = outlineView.row(at: location)
    if row < 0 { return }
    outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
    OutlineModel.selected.onNext(outlineView.item(atRow: row) as! OutlineModel)
  }
}

extension OutlineViewController: NSOutlineViewDataSource, NSOutlineViewDelegate {
  func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
    guard let outline = item as? OutlineModel else { return outlines.count }
    return outline.children?.count ?? 0
  }
  
  func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
    guard let outline = item as? OutlineModel else { return outlines[index] }
    return outline.children![index]
  }
  
  func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
    return (item as! OutlineModel).children != nil
  }
  
  func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
    let identifier = NSUserInterfaceItemIdentifier(rawValue: "default")
    let cell = outlineView.makeView(withIdentifier: identifier, owner: self) as! NSTableCellView
    cell.textField?.stringValue = (item as! OutlineModel).title
    return cell
  }
  
  func outlineView(_ outlineView: NSOutlineView, persistentObjectForItem item: Any?) -> Any? {
    return (item as! OutlineModel).title
  }
  
  func outlineView(_ outlineView: NSOutlineView, itemForPersistentObject object: Any) -> Any? {
    let title = object as! String
    return outlineDictionary[title]
  }
}
