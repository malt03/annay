//
//  WorkspacePreferenceViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/17.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxCocoa
import RxSwift

final class WorkspacePreferenceViewController: NSViewController {
  private let bag = DisposeBag()
  
  @IBOutlet private weak var workspaceTextField: NSTextField!
  @IBAction private func selectWorkspace(_ sender: NSButton) {
    let openPanel = NSOpenPanel()
    openPanel.allowsMultipleSelection = false
    openPanel.canChooseDirectories = true
    openPanel.canCreateDirectories = true
    openPanel.canChooseFiles = false
    openPanel.begin { (result) in
      if result != .OK { return }
      guard let url = openPanel.url else { return }
      WorkspaceManager.shared.updateWorkspace(url)
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    WorkspaceManager.shared.workspaceString.bind(to: workspaceTextField.rx.text).disposed(by: bag)
  }
}
