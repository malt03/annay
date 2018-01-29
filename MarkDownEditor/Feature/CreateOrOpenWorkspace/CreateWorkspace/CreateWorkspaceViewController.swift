//
//  CreateWorkspaceViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/20.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift

final class CreateWorkspaceViewController: NSViewController {
  private let bag = DisposeBag()
  
  @IBOutlet private weak var workspaceDirectoryTextField: NSTextField!
  @IBOutlet private weak var workspaceNameTextField: NSTextField!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    
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
      let homePath = FileManager.default.homeDirectoryForCurrentUser.path
      s.workspaceDirectoryTextField.stringValue = url.path.replacingOccurrences(of: "^\(homePath)", with: "~", options: .regularExpression)
    }
  }
  
  @IBAction func createWorkspace(_ sender: NSButton) {
    let homePath = FileManager.default.homeDirectoryForCurrentUser.path
    let path = workspaceDirectoryTextField.stringValue.replacingOccurrences(of: "^~", with: homePath, options: .regularExpression)
    var isDirectory = ObjCBool(booleanLiteral: true)
    if !FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) || !isDirectory.boolValue {
      let alert = NSAlert()
      alert.messageText = Localized("Directory not found.")
      alert.runModal()
      return
    }
    do {
      let url = URL(fileURLWithPath: path, isDirectory: true)
      try WorkspaceModel(url: url).save()
      view.window?.close()
    } catch {
      let alert = NSAlert(error: error)
      alert.runModal()
    }
  }
  
  override func dismiss(_ sender: Any?) {
    view.window?.close()
  }
}
