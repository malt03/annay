//
//  NodeTableCellView.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/12.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RealmSwift
import RxSwift
import RxRealm

final class NodeTableCellView: NSTableCellView {
  private let bag = DisposeBag()
  private let nodeDisposable = SerialDisposable()
  
  @IBOutlet private weak var editedView: BackgroundSetableView?
  
  private var node: NodeModel!
  private var inPreference = false
  
  func prepare(node: NodeModel, inPreference: Bool = false) {
    self.node = node
    self.inPreference = inPreference
    
    textField?.isEditable = !inPreference && node.isDirectory && !node.isDeleted && !node.isTrash
    textField?.font = NSFont.systemFont(ofSize: 14)
    imageView?.image = NSImage(named: NSImage.folderName)
    
    observeNode()
  }
  
  private func observeNode() {
    nodeDisposable.disposable = Observable.from(object: node).subscribe(onNext: { [weak self] (node) in
      guard let s = self else { return }
      s.textField?.stringValue = node.name
      s.editedView?.isHidden = node.isBodySaved
    })
    nodeDisposable.disposed(by: bag)
  }
  
  @IBAction private func edited(_ sender: NSTextField) {
    Realm.transaction { _ in
      alertError { try self.node.setDirectoryName(sender.stringValue) }
    }
  }
}
