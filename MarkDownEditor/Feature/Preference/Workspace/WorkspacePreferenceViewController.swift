//
//  WorkspacePreferenceViewController.swift
//  Annay
//
//  Created by Koji Murata on 2018/04/12.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift

final class WorkspacePreferenceViewController: NSViewController {
  private let bag = DisposeBag()
  
  @IBOutlet private weak var workspacePopUpButton: NSPopUpButton!
  override func viewDidLoad() {
    super.viewDidLoad()
    WorkspaceModel.observableSpaces.subscribe(onNext: { [weak self] (spaces) in
      guard let s = self else { return }
      s.workspacePopUpButton.removeAllItems()
      s.workspacePopUpButton.addItems(withTitles: spaces.map { $0.nameValue })
    }).disposed(by: bag)
  }
  
}
