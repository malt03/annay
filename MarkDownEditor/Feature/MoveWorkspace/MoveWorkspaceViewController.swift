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
  private let isFolderSubject = BehaviorSubject<Bool>(value: true)
  
  @IBOutlet private weak var workspaceNameTextField: NSTextField!
  @IBOutlet private weak var workspaceDirectoryTextField: NSTextField!
  @IBOutlet private weak var fileTypePopUpButton: NSPopUpButton!
  @IBOutlet private weak var moveButton: NSButton!

  private var workspace: WorkspaceModel!
  
  func prepare(workspace: WorkspaceModel) {
    self.workspace = workspace
    fileTypePopUpButton.selectItem(at: workspace.isFolderUrl ? 1 : 0)
    isFolderSubject.onNext(workspace.isFolderUrl)
//    workspaceDirectoryTextField.stringValue = workspace.directoryUrl.deletingLastPathComponent().replacingHomePath
    workspaceNameTextField.stringValue = workspace.nameValue
    workspaceNameTextField.rx.text.onNext(workspace.nameValue)
  }
  
  private var isFolder: Bool {
    return fileTypePopUpButton.indexOfSelectedItem == 1
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
    
    moveButton.isEnabled = false
    
    Observable.combineLatest(directory, name, isFolderSubject, resultSelector: { [weak self] (directory, _, isFolder) -> Bool in
      guard
        let s = self,
        let directory = directory
        else { return false }

      let name = s.workspaceNameTextField.stringValue

      if directory == "" { return false }
      if name == "" { return false }

      var isDirectory = ObjCBool(booleanLiteral: false)
      let path = directory.replacingTildeToHomePath
      let oldUrl = s.workspace.directoryUrl
      let newUrl = URL(fileURLWithPath: path).appendingPathComponent(name).appendingPathExtension(isFolder: isFolder)
      if newUrl.isEqualIgnoringLastSlash(oldUrl) {
        return false
      }
      if FileManager.default.fileExists(atPath: newUrl.path) { return false }
      let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
      if !exists { return false }
      return isDirectory.boolValue
    }).bind(to: moveButton.rx.isEnabled).disposed(by: bag)
  }
  
  @IBAction private func showFileTypeHint(_ sender: NSButton) {
    NSAlert(localizedMessageText: "You can select file type which Annay save the markdown files.\nI recommend to select \"Package\" unless there are special circumstances.\nYou could select \"Directory\" when you will use tools such as Box Sync which do not support macOS package files.").runModal()
  }
  
  @IBAction private func changeIsFolder(_ sender: NSPopUpButton) {
    isFolderSubject.onNext(isFolder)
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
      let url = URL(fileURLWithPath: path, isDirectory: true).appendingPathComponent(name).appendingPathExtension(isFolder: isFolder)
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
