//
//  MoveWorkspaceViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/26.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class MoveWorkspaceViewController: NSViewController {
  private var workspace: WorkspaceModel!
  func prepare(workspace: WorkspaceModel) {
    self.workspace = workspace
    workspaceTextField.stringValue = workspace.url.value.replacingHomePath
  }
  
  @IBOutlet private weak var workspaceTextField: NSTextField!
  @IBAction private func selectWorkspace(_ sender: NSButton) {
    guard let window = view.window else { return }
    let openPanel = NSOpenPanel()
    openPanel.allowsMultipleSelection = false
    openPanel.canChooseDirectories = true
    openPanel.canCreateDirectories = true
    openPanel.canChooseFiles = false
    openPanel.directoryURL = workspace.url.value
    openPanel.beginSheetModal(for: window) { [weak self] (result) in
      guard let s = self else { return }
      if result != .OK { return }
      guard let url = openPanel.url else { return }
      s.workspaceTextField.stringValue = url.replacingHomePath
    }
  }
  
  @IBAction func moveWorkspace(_ sender: NSButton) {
    let homePath = FileManager.default.homeDirectoryForCurrentUser.path
    let path = workspaceTextField.stringValue.replacingOccurrences(of: "^~", with: homePath, options: .regularExpression)
    var isDirectory = ObjCBool(booleanLiteral: true)
    if !FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) || !isDirectory.boolValue {
      let alert = NSAlert()
      alert.messageText = Localized("Directory not found.")
      alert.runModal()
      return
    }
    do {
      let contents = try FileManager.default.contentsOfDirectory(atPath: path)
      if contents.count != 0 {
        let alert = NSAlert()
        alert.messageText = Localized("Directory not empty.")
        alert.runModal()
        return
      }
      let url = URL(fileURLWithPath: path, isDirectory: true)
      try FileManager.default.removeItem(at: url)
      try FileManager.default.moveItem(at: workspace.url.value, to: url)
      workspace.url.value = url
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
