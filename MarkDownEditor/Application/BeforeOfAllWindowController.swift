//
//  BeforeOfAllWindowController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/04.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RealmSwift

final class BeforeOfAllWindowController: NSWindowController {
  override func windowDidLoad() {
    super.windowDidLoad()
    
    DispatchQueue.main.async {
      WorkspaceDirectoryWatcherManager.shared.prepare(confirm: self.createConfirmUpdateNoteHandler())
      
      alertError {
        try self.reloadWorkspaces()
        try WorkspaceModel.createDefaultIfNeeded()
      }
      
      ShortcutPreference.shared.prepare()
      
      (Application.shared as! Application).prepareForWorkspaces()
      
      let storyboard = NSStoryboard(name: "Main", bundle: .main)
      let windowController = (storyboard.instantiateInitialController() as! NSWindowController)
      windowController.windowFrameAutosaveName = "MainWindow"
      windowController.showWindow(nil)
      self.close()
      
      self.removeUnnecessaryFiles()
    }
  }
  
  private func reloadWorkspaces() throws {
    try Realm.transaction { (realm) in
      for workspace in WorkspaceModel.spaces {
        try workspace.updateIndex(confirmUpdateNote: createConfirmUpdateNoteHandler(), realm: realm)
      }
    }
  }
  
  private func createConfirmUpdateNoteHandler() -> NodeModel.ConfirmUpdateNote {
    return { (node, confirm) in
      let alert = NSAlert()
      alert.messageText = String(format: Localized("File update for '%@' was detected.\nWhich one should take priority?"), node.name)
      alert.addButton(withTitle: Localized("File"))
      alert.addButton(withTitle: Localized("Editing Data"))
      try confirm(alert.runModal() == .alertFirstButtonReturn)
    }
  }
  
  private func removeUnnecessaryFiles() {
    DispatchQueue.global(qos: .background).async {
      let fileManager = FileManager.default
      do {
        for workspace in WorkspaceModel.getSpaces() {
          for resource in try fileManager.contentsOfDirectory(at: workspace.directoryUrl.resourceDirectory, includingPropertiesForKeys: [], options: []) {
            if !NodeModel.containsBody(resource.absoluteString, in: workspace) {
              try fileManager.removeItem(at: resource)
            }
          }
        }
      } catch {}
    }
  }
}
