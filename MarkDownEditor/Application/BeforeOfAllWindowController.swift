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
      WorkspaceDirectoryWatcherManager.shared.prepare()
      NodeModel.createFirstDirectoryIfNeeded()
      
      NewWorkspaceShortcutManager.shared.prepare()
      
      for workspace in WorkspaceModel.spaces.value { workspace.saveToUserDefaults() }
      let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: .main)
      (storyboard.instantiateInitialController() as! NSWindowController).showWindow(nil)
      self.close()
    }
  }
}
