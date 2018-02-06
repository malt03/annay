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
import RxCocoa

final class WorkspacesTableCellView: NSTableCellView {
  private let bag = DisposeBag()
  private let textDisposable = SerialDisposable()
  private let editedDisposable = SerialDisposable()
  @IBOutlet private weak var backgroundView: BackgroundSetableView!
  @IBOutlet private weak var editedView: BackgroundSetableView!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    textField?.font = NSFont.systemFont(ofSize: 16)
  }
  
  func prepare(workspace: WorkspaceModel) {
    textDisposable.disposable = workspace.nameObservable.map { $0.firstCharacterString }.bind(to: textField!.rx.text)
    editedDisposable.disposable = workspace.savedObservable.bind(to: editedView.rx.isHidden)
    textDisposable.disposed(by: bag)
    editedDisposable.disposed(by: bag)
  }
  
  override var backgroundStyle: NSView.BackgroundStyle {
    get { return super.backgroundStyle }
    set {
      super.backgroundStyle = newValue
      backgroundView.backgroundColor = backgroundStyle == .dark ? .focus : .editorBackground
    }
  }
}
