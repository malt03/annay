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
  
  private let selectedWorkspace = Variable(WorkspaceModel.selectedValue)
  
  @IBOutlet private weak var workspacePopUpButton: NSPopUpButton!
  @IBOutlet private weak var fileTypePopUpButton: NSPopUpButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    WorkspaceModel.observableSpaces.distinctUntilChanged().subscribe(onNext: { [weak self] (spaces) in
      guard let s = self else { return }
      s.workspacePopUpButton.removeAllItems()
      s.workspacePopUpButton.addItems(withTitles: spaces.map { $0.nameValue })
    }).disposed(by: bag)
    
    workspacePopUpButton.rx.controlEvent.subscribe(onNext: { [weak self] _ in
      guard let s = self else { return }
      s.selectedWorkspace.value = WorkspaceModel.spaces[s.workspacePopUpButton.indexOfSelectedItem]
    }).disposed(by: bag)

    selectedWorkspace.asObservable().subscribe(onNext: { [weak self] (workspace) in
      guard let s = self else { return }
      let index = workspace.isFolderUrl ? 1 : 0
      s.fileTypePopUpButton.selectItem(at: index)
    }).disposed(by: bag)

    fileTypePopUpButton.rx.controlEvent.subscribe(onNext: { [weak self] _ in
      guard let s = self else { return }
      alertError {
        try s.selectedWorkspace.value.setIsFolderUrl(s.fileTypePopUpButton.indexOfSelectedItem == 1)
      }
    }).disposed(by: bag)
  }
}
