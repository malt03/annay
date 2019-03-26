//
//  MoveWorkspaceViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/26.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift
import RealmSwift

final class MoveWorkspaceViewController: NSViewController {
  private let bag = DisposeBag()
  private let setDirectory = BehaviorSubject<String?>(value: nil)
  
  @IBOutlet private weak var workspaceNameTextField: NSTextField!
  @IBOutlet private weak var workspaceDirectoryTextField: NSTextField!
  @IBOutlet private weak var moveButton: NSButton!

  private var workspace: WorkspaceModel!
  
  func prepare(workspace: WorkspaceModel) {
    self.workspace = workspace
    workspaceDirectoryTextField.stringValue = workspace.directoryUrl.deletingLastPathComponent().replacingHomePath
    setDirectory.onNext(workspaceDirectoryTextField.stringValue)
    workspaceNameTextField.stringValue = workspace.nameValue
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setDirectory.subscribe(onNext: { [weak self] (path) in
      guard let s = self else { return }
      s.workspaceDirectoryTextField.stringValue = path ?? ""
      s.view.window?.makeFirstResponder(s.workspaceDirectoryTextField)
    }).disposed(by: bag)
    
    let directory = Observable.merge(workspaceDirectoryTextField.rx.text.asObservable(), setDirectory)
    let name = workspaceNameTextField.rx.text
    Observable.combineLatest(directory, name, resultSelector: { [weak self] (directory, name) -> Bool in
      guard
        let s = self,
        let directory = directory,
        let name = name
        else { return false }

      if directory == "" { return false }
      if name == "" { return false }

      var isDirectory = ObjCBool(booleanLiteral: false)
      let path = directory.replacingTildeToHomePath
      let oldUrl = s.workspace.directoryUrl
      let newUrl = URL(fileURLWithPath: path).appendingPathComponent(name).appendingPathExtension(URL.workspaceExtension)
      if newUrl.isEqualIgnoringLastSlash(oldUrl) {
        return false
      }
      if FileManager.default.fileExists(atPath: newUrl.path) { return false }
      let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
      if !exists { return false }
      return isDirectory.boolValue
    }).bind(to: moveButton.rx.isEnabled).disposed(by: bag)
  }
  

  @IBAction private func selectWorkspace(_ sender: NSButton) {
    guard let window = view.window else { return }
    let openPanel = NSOpenPanel()
    openPanel.allowsMultipleSelection = false
    openPanel.canChooseDirectories = true
    openPanel.canCreateDirectories = true
    openPanel.canChooseFiles = false
    openPanel.directoryURL = workspace.directoryUrl
    openPanel.beginSheetModal(for: window) { [weak self] (result) in
      guard let s = self else { return }
      if result != .OK { return }
      guard let url = openPanel.url else { return }
      s.setDirectory.onNext(url.replacingHomePath)
      BookmarkManager.shared.bookmark(url: url)
    }
  }
  
  @IBAction func moveWorkspace(_ sender: NSButton) {
    let path = workspaceDirectoryTextField.stringValue.replacingTildeToHomePath
    let name = workspaceNameTextField.stringValue
    do {
      let url = URL(fileURLWithPath: path, isDirectory: true).appendingPathComponent(name).appendingPathExtension(URL.workspaceExtension)
      try Realm.transaction { _ in
        try workspace.setDirectoryUrl(url)
      }
      view.window?.close()
    } catch {
      NSAlert(error: error).runModal()
    }
  }
  
  override func dismiss(_ sender: Any?) {
    view.window?.close()
  }

}
