//
//  OpenWorkspaceViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/29.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift

final class OpenWorkspaceViewController: NSViewController {
  private let bag = DisposeBag()
  
  @IBOutlet private weak var workspaceFileTextField: NSTextField!
  @IBOutlet private weak var openButton: NSButton!
  
  private let setFile = PublishSubject<String?>()
  
  override func becomeFirstResponder() -> Bool {
    workspaceFileTextField.becomeFirstResponder()
    return true
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setFile.subscribe(onNext: { [weak self] (path) in
      guard let s = self else { return }
      s.workspaceFileTextField.stringValue = path ?? ""
      s.view.window?.makeFirstResponder(s.workspaceFileTextField)
    }).disposed(by: bag)
    
    Observable.merge(workspaceFileTextField.rx.text.asObservable(), setFile).map { (directory) -> Bool in
      guard let directory = directory else { return false }
      if directory == "" { return false }
      return URL(fileURLWithPath: directory.replacingTildeToHomePath).isWorkspace
    }.bind(to: openButton.rx.isEnabled).disposed(by: bag)
  }
  
  @IBAction private func selectWorkspace(_ sender: NSButton) {
    guard let window = view.window else { return }
    let openPanel = NSOpenPanel()
    openPanel.allowsMultipleSelection = false
    openPanel.canChooseDirectories = false
    openPanel.canCreateDirectories = false
    openPanel.canChooseFiles = true
    openPanel.delegate = self
    
    openPanel.allowedFileTypes = [WorkspaceModel.fileExtension]
    openPanel.beginSheetModal(for: window) { [weak self] (result) in
      guard let s = self else { return }
      if result != .OK { return }
      guard let url = openPanel.url else { return }
      s.setFile.onNext(url.replacingHomePath)
    }
  }
  
  @IBAction func openWorkspace(_ sender: NSButton) {
    let path = workspaceFileTextField.stringValue.replacingTildeToHomePath
    if WorkspaceModel.open(url: URL(fileURLWithPath: path)) {
      view.window?.close()
    }
  }
  
  override func dismiss(_ sender: Any?) {
    view.window?.close()
  }
}

extension OpenWorkspaceViewController: NSOpenSavePanelDelegate {
  func panel(_ sender: Any, shouldEnable url: URL) -> Bool {
    var isDirectory = ObjCBool(booleanLiteral: false)
    if !FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) { return false }
    return isDirectory.boolValue
  }
}