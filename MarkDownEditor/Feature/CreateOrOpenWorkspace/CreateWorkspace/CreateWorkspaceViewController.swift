//
//  CreateWorkspaceViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/20.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift
import RealmSwift

final class CreateWorkspaceViewController: CreateOrOpenWorkspaceViewController {
  private let bag = DisposeBag()
  
  @IBOutlet private weak var workspaceDirectoryTextField: NSTextField!
  @IBOutlet private weak var workspaceNameTextField: NSTextField!
  @IBOutlet private weak var fileTypePopUpButton: NSPopUpButton!
  @IBOutlet private weak var createButton: NSButton!
  
  private let setDirectory = PublishSubject<String?>()

  override func becomeFirstResponder() -> Bool {
    workspaceNameTextField.becomeFirstResponder()
    return true
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    setDirectory.subscribe(onNext: { [weak self] (path) in
      guard let s = self else { return }
      s.workspaceDirectoryTextField.stringValue = path ?? ""
      s.view.window?.makeFirstResponder(s.workspaceDirectoryTextField)
    }).disposed(by: bag)

    let directoryValidate = Observable.merge(workspaceDirectoryTextField.rx.text.asObservable(), setDirectory).map { (directory) -> Bool in
      guard let directory = directory else { return false }
      if directory == "" { return false }
      var isDirectory = ObjCBool(booleanLiteral: false)
      let exists = FileManager.default.fileExists(atPath: directory.replacingTildeToHomePath, isDirectory: &isDirectory)
      if !exists { return false }
      return isDirectory.boolValue
    }
    let nameValidate = workspaceNameTextField.rx.text.map { $0 != nil && $0 != "" }
    Observable.combineLatest(directoryValidate, nameValidate, resultSelector: { $0 && $1 }).bind(to: createButton.rx.isEnabled).disposed(by: bag)
  }
  
  @IBAction private func showFileTypeHint(_ sender: NSButton) {
    NSAlert(localizedMessageText: "You can select file type which Annay save the markdown files.\nI recommend to select \"Package\" unless there are special circumstances.\nYou could select \"Directory\" when you will use tools such as Box Sync which do not support macOS package files.").runModal()
  }
  
  @IBAction private func selectWorkspace(_ sender: NSButton) {
    guard let window = view.window else { return }
    let openPanel = NSOpenPanel()
    openPanel.allowsMultipleSelection = false
    openPanel.canChooseDirectories = true
    openPanel.canCreateDirectories = true
    openPanel.canChooseFiles = false
    openPanel.beginSheetModal(for: window) { [weak self] (result) in
      guard let s = self else { return }
      if result != .OK { return }
      guard let url = openPanel.url else { return }
      s.setDirectory.onNext(url.replacingHomePath)
      BookmarkManager.shared.bookmark(url: url)
    }
  }
  
  @IBAction private func createWorkspace(_ sender: NSButton) {
    let path = workspaceDirectoryTextField.stringValue.replacingTildeToHomePath
    let url = URL(fileURLWithPath: path, isDirectory: true)
    let isFolder = fileTypePopUpButton.indexOfSelectedItem == 1
    alertError { try WorkspaceModel.create(name: workspaceNameTextField.stringValue, parentDirectory: url, isFolder: isFolder) }
    view.window?.close()
  }
  
  override func dismiss(_ sender: Any?) {
    view.window?.close()
  }
}
