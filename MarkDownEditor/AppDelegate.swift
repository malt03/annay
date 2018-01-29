//
//  AppDelegate.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/09.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RealmSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationWillFinishLaunching(_ notification: Notification) {
    WorkspaceDirectoryWatcherManager.shared.prepare()
  }
  
  func application(_ sender: NSApplication, openFile filename: String) -> Bool {
    if let index = WorkspaceModel.spaces.value.map({ $0.url.value.path }).index(of: filename) {
      WorkspaceModel.spaces.value[index].select()
    } else {
      do {
        try WorkspaceModel(url: URL(fileURLWithPath: filename)).save()
      } catch {
        NSAlert(error: error).runModal()
        return false
      }
    }
    return true
  }
}

extension AppDelegate {
  @IBAction private func openQuickly(_ sender: NSMenuItem) {
    OpenQuicklyWindowController.toggle()
  }
  
  @IBAction private func revealInSidebar(_ sender: NSMenuItem) {
    NotificationCenter.default.post(name: .RevealInSidebar, object: nil)
  }
  
  @IBAction private func selectNextWorkspace(_ sender: NSMenuItem) {
    NotificationCenter.default.post(name: .SelectNextWorkspace, object: nil)
  }
  
  @IBAction private func selectPreviousWorkspace(_ sender: NSMenuItem) {
    NotificationCenter.default.post(name: .SelectPreviousWorkspace, object: nil)
  }
  
  @IBAction private func moveFocusToSidebar(_ sender: NSMenuItem) {
    NotificationCenter.default.post(name: .MoveFocusToSidebar, object: nil)
  }
  
  @IBAction private func moveFocusToEditor(_ sender: NSMenuItem) {
    NotificationCenter.default.post(name: .MoveFocusToEditor, object: nil)
  }
}

extension Notification.Name {
  static let RevealInSidebar = Notification.Name(rawValue: "AppDelegate/RevealInSidebar")
  static let SelectNextWorkspace = Notification.Name(rawValue: "AppDelegate/SelectNextWorkspace")
  static let SelectPreviousWorkspace = Notification.Name(rawValue: "AppDelegate/SelectPreviousWorkspace")
  static let MoveFocusToSidebar = Notification.Name(rawValue: "AppDelegate/MoveFocusToSidebar")
  static let MoveFocusToEditor = Notification.Name(rawValue: "AppDelegate/MoveFocusToEditor")
}
