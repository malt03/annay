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
  private let imageDisposable = SerialDisposable()
  private let textDisposable = SerialDisposable()
  
  override func awakeFromNib() {
    super.awakeFromNib()
    textField?.font = NSFont.systemFont(ofSize: 16)
  }
  
  func prepare(workspace: WorkspaceModel) {
    imageDisposable.disposable = workspace.imageUrl.asObservable().subscribe(onNext: { [weak self] (url) in
      self?.imageView?.kf.setImage(with: url)
    })
    textDisposable.disposable = workspace.name.asObservable().map { $0.firstCharacterString }.bind(to: textField!.rx.text)

    imageDisposable.disposed(by: bag)
    textDisposable.disposed(by: bag)
  }
}
