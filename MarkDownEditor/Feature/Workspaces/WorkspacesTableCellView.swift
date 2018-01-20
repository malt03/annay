//
//  WorkspacesTableCellView.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/18.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import Kingfisher
import RxSwift

final class WorkspacesTableCellView: NSTableCellView {
  private let bag = DisposeBag()
  private let textDisposable = SerialDisposable()
  @IBOutlet private weak var backgroundView: BackgroundSetableView!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    textField?.font = NSFont.systemFont(ofSize: 16)
  }
  
  func prepare(workspace: WorkspaceModel) {
    textDisposable.disposable = workspace.name.asObservable().map { $0.firstCharacterString }.bind(to: textField!.rx.text)
    textDisposable.disposed(by: bag)
  }
  
  
}
