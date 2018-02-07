//
//  NewWorkspaceShortcutPreferenceViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/07.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift

class NewWorkspaceShortcutPreferenceViewController: NSViewController {
  private let bag = DisposeBag()
  
  @IBOutlet private weak var popUpButton: NSPopUpButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    WorkspaceModel.spaces.asObservable().subscribe(onNext: { [weak self] (spaces) in
      guard let s = self else { return }
      s.popUpButton.removeAllItems()
      s.popUpButton.addItems(withTitles: spaces.map { $0.name })
    }).disposed(by: bag)
  }
}
