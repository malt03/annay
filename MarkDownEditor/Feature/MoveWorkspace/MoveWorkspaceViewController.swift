//
//  MoveWorkspaceViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/26.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift

final class MoveWorkspaceViewController: NSViewController {
  private let bag = DisposeBag()
  private let setDirectory = PublishSubject<String?>()
  
  @IBOutlet private weak var workspaceDirectoryTextField: NSTextField!
  @IBOutlet private weak var moveButton: NSButton!

  private var workspace: WorkspaceModel!
  
  func prepare(workspace: WorkspaceModel) {
    self.workspace = workspace
    workspaceDirectoryTextField.stringValue = workspace.url.deletingLastPathComponent().replacingHomePath
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setDirectory.subscribe(onNext: { [weak self] (path) in
      guard let s = self else { return }
      s.workspaceDirectoryTextField.stringValue = path ?? ""
      s.view.window?.makeFirstResponder(s.workspaceDirectoryTextField)
    }).disposed(by: bag)
    
    Observable.merge(workspaceDirectoryTextField.rx.text.asObservable(), setDirectory).map { [weak self] (directory) -> Bool in
      guard let s = self else { return false }
      guard let directory = directory else { return false }
      if directory == "" { return false }
      var isDirectory = ObjCBool(booleanLiteral: false)
      let path = directory.replacingTildeToHomePath
      let oldUrl = s.workspace.url
      if URL(fileURLWithPath: path).appendingPathComponent(oldUrl.lastPathComponent).isEqualIgnoringLastSlash(oldUrl) {
        return false
      }
      let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
      if !exists { return false }
      return isDirectory.boolValue
    }.bind(to: moveButton.rx.isEnabled).disposed(by: bag)
  }
  

  @IBAction private func selectWorkspace(_ sender: NSButton) {
    guard let window = view.window else { return }
    let openPanel = NSOpenPanel()
    openPanel.allowsMultipleSelection = false
    openPanel.canChooseDirectories = true
    openPanel.canCreateDirectories = true
    openPanel.canChooseFiles = false
    openPanel.directoryURL = workspace.url
    openPanel.beginSheetModal(for: window) { [weak self] (result) in
      guard let s = self else { return }
      if result != .OK { return }
      guard let url = openPanel.url else { return }
      s.setDirectory.onNext(url.replacingHomePath)
    }
  }
  
  @IBAction func moveWorkspace(_ sender: NSButton) {
    let path = workspaceDirectoryTextField.stringValue.replacingTildeToHomePath
    do {
      let url = URL(fileURLWithPath: path, isDirectory: true).appendingPathComponent(workspace.url.lastPathComponent)
      try workspace.setUrl(url)
      view.window?.close()
    } catch {
      NSAlert(error: error).runModal()
    }
  }
  
  override func dismiss(_ sender: Any?) {
    view.window?.close()
  }

}
