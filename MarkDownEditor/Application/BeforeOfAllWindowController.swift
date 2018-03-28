//
//  BeforeOfAllWindowController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/04.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class BeforeOfAllWindowController: NSWindowController {
  override func windowDidLoad() {
    super.windowDidLoad()
    
    DispatchQueue.main.async {
      ResourceManager.prepare()
      
      WorkspaceDirectoryWatcherManager.shared.prepare(confirm: { (node, confirm) in
        let alert = NSAlert()
        alert.messageText = String(format: Localized("File update for '%@' was detected.\nWhich one should take priority?"), node.name)
        alert.addButton(withTitle: Localized("File"))
        alert.addButton(withTitle: Localized("Editing Data"))
        try confirm(alert.runModal() == .alertFirstButtonReturn)
      })
      
      alertError { try WorkspaceModel.createDefaultIfNeeded() }
      
      ShortcutPreference.shared.prepare()
      
      (Application.shared as! Application).prepareForWorkspaces()
      
      let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: .main)
      let windowController = (storyboard.instantiateInitialController() as! NSWindowController)
      windowController.windowFrameAutosaveName = NSWindow.FrameAutosaveName("MainWindow")
      windowController.showWindow(nil)
      self.close()
      
      self.removeUnnecessaryFiles()
    }
  }
  
  private func removeUnnecessaryFiles() {
//    DispatchQueue.global(qos: .background).async {
//      let fileManager = FileManager.default
//      do { try fileManager.removeItem(at: fileManager.applicationTmp) } catch {}
//      do {
//        let directories = Set(try fileManager.contentsOfDirectory(atPath: fileManager.applicationWorkspace.path))
//        let spaces = Set(WorkspaceModel.spaces.map { $0.workspaceDirectoryName })
//        for unnecessary in directories.subtracting(spaces) {
//          try fileManager.removeItem(at: fileManager.applicationWorkspace.appendingPathComponent(unnecessary))
//        }
//      } catch {}
//      do {
//        for resource in try fileManager.contentsOfDirectory(atPath: ResourceManager.resourceUrl.path) {
//          var containsFlag = false
//          for workspace in WorkspaceModel.spaces {
//            if NodeModel.containsBody(resource, in: workspace) {
//              containsFlag = true
//              break
//            }
//          }
//          if !containsFlag {
//            try fileManager.removeItem(at: ResourceManager.resourceUrl.appendingPathComponent(resource))
//          }
//        }
//      } catch {}
//      do {
//        for workspace in WorkspaceModel.spaces.value {
//          for resource in try fileManager.contentsOfDirectory(atPath: workspace.workspaceDirectory.resourceDirectory.path) {
//            if !NodeModel.containsBody(resource, in: workspace) {
//              try fileManager.removeItem(at: workspace.workspaceDirectory.resourceDirectory.appendingPathComponent(resource))
//            }
//          }
//        }
//      } catch {}
//    }
  }
}
