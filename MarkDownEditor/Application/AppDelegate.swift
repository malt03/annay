//
//  AppDelegate.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/09.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RealmSwift
import CoreSpotlight

@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {
  func application(_ application: NSApplication, open urls: [URL]) {
    guard let url = urls.first else { return }
    if url.isFileURL {
      alertError { try WorkspaceModel.create(directoryUrl: url) }
      return
    }

    if url.scheme != "annay" { return }
    let nodeId = url.lastPathComponent
    guard
      let node = NodeModel.node(for: nodeId)
      else { return }
    node.workspace?.select()
    node.select()
  }
  
  func application(_ application: NSApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([NSUserActivityRestoring]) -> Void) -> Bool {
    if userActivity.activityType == CSSearchableItemActionType {
      guard
        let nodeId = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
        let node = NodeModel.node(for: nodeId)
        else { return false }
      node.workspace?.select()
      node.select()
    }
    return true
  }
}

extension AppDelegate {
  @IBAction private func findInWorkspace(_ sender: NSMenuItem)          { NotificationCenter.default.post(name: .FindInWorkspace, object: nil) }
  @IBAction private func openWorkspace(_ sender: NSMenuItem)            { NotificationCenter.default.post(name: .OpenWorkspace, object: nil) }
  @IBAction private func createNote(_ sender: NSMenuItem)               { NotificationCenter.default.post(name: .CreateNote, object: nil) }
  @IBAction private func createDirectory(_ sender: NSMenuItem)          { NotificationCenter.default.post(name: .CreateDirectory, object: nil) }
  @IBAction private func createGroup(_ sender: NSMenuItem)              { NotificationCenter.default.post(name: .CreateGroup, object: nil) }
  @IBAction private func createWorkspace(_ sender: NSMenuItem)          { NotificationCenter.default.post(name: .CreateWorkspace, object: nil) }
  @IBAction private func revealInSidebar(_ sender: NSMenuItem)          { NotificationCenter.default.post(name: .RevealInSidebar, object: nil) }
  @IBAction private func selectNextNote(_ sender: NSMenuItem)           { NotificationCenter.default.post(name: .SelectNextNote, object: nil) }
  @IBAction private func selectPreviousNote(_ sender: NSMenuItem)       { NotificationCenter.default.post(name: .SelectPreviousNote, object: nil) }
  @IBAction private func selectNextWorkspace(_ sender: NSMenuItem)      { NotificationCenter.default.post(name: .SelectNextWorkspace, object: nil) }
  @IBAction private func selectPreviousWorkspace(_ sender: NSMenuItem)  { NotificationCenter.default.post(name: .SelectPreviousWorkspace, object: nil) }
  @IBAction private func moveFocusToWorkspaces(_ sender: NSMenuItem)    { NotificationCenter.default.post(name: .MoveFocusToWorkspaces, object: nil) }
  @IBAction private func moveFocusToSidebar(_ sender: NSMenuItem)       { NotificationCenter.default.post(name: .MoveFocusToSidebar, object: nil) }
  @IBAction private func moveFocusToEditor(_ sender: NSMenuItem)        { NotificationCenter.default.post(name: .MoveFocusToEditor, object: nil) }
  @IBAction private func deleteNote(_ sender: NSMenuItem)               { NotificationCenter.default.post(name: .DeleteNote, object: nil) }
  @IBAction private func deleteNoteImmediately(_ sender: NSMenuItem)    { NotificationCenter.default.post(name: .DeleteNoteImmediately, object: nil) }
  @IBAction private func putBackNote(_ sender: NSMenuItem)              { NotificationCenter.default.post(name: .PutBackNote, object: nil) }
  @IBAction private func emptyTrash(_ sender: NSMenuItem)               { NotificationCenter.default.post(name: .EmptyTrash, object: nil) }
  @IBAction private func actualSize(_ sender: NSMenuItem)               { NotificationCenter.default.post(name: .ActualSize, object: nil) }
  @IBAction private func zoomIn(_ sender: NSMenuItem)                   { NotificationCenter.default.post(name: .ZoomIn, object: nil) }
  @IBAction private func zoomOut(_ sender: NSMenuItem)                  { NotificationCenter.default.post(name: .ZoomOut, object: nil) }


  @IBAction private func openQuickly(_ sender: NSMenuItem) {
    OpenQuicklyWindowController.toggle()
  }

  @IBAction private func openPreference(_ sender: NSMenuItem) {
    PreferenceWindowController.show()
  }

  @IBAction private func saveNote(_ sender: NSMenuItem) {
    Realm.transaction { _ in
      alertError { try NodeModel.selectedNode.value?.save() }
    }
  }

  @IBAction private func saveAllNotes(_ sender: NSMenuItem) {
    Realm.transaction { _ in
      alertError {
        try NodeModel.saveAll(for: WorkspaceModel.selectedValue)
      }
    }
  }

  @IBAction private func openTwitter(_ sender: NSMenuItem) {
    NSWorkspace.shared.open(URL(string: "https://twitter.com/malt03")!)
  }
}

extension Notification.Name {
  static let FindInWorkspace = Notification.Name(rawValue: "AppDelegate/FindInWorkspace")
  static let OpenWorkspace = Notification.Name(rawValue: "AppDelegate/OpenWorkspace")
  static let RevealInSidebar = Notification.Name(rawValue: "AppDelegate/RevealInSidebar")
  static let CreateNote = Notification.Name(rawValue: "AppDelegate/CreateNote")
  static let CreateDirectory = Notification.Name(rawValue: "AppDelegate/CreateDirectory")
  static let CreateGroup = Notification.Name(rawValue: "AppDelegate/CreateGroup")
  static let CreateWorkspace = Notification.Name(rawValue: "AppDelegate/CreateWorkspace")
  static let SelectNextNote = Notification.Name(rawValue: "AppDelegate/SelectNextNote")
  static let SelectPreviousNote = Notification.Name(rawValue: "AppDelegate/SelectPreviousNote")
  static let SelectNextWorkspace = Notification.Name(rawValue: "AppDelegate/SelectNextWorkspace")
  static let SelectPreviousWorkspace = Notification.Name(rawValue: "AppDelegate/SelectPreviousWorkspace")
  static let MoveFocusToWorkspaces = Notification.Name(rawValue: "AppDelegate/MoveFocusToWorkspaces")
  static let MoveFocusToSidebar = Notification.Name(rawValue: "AppDelegate/MoveFocusToSidebar")
  static let MoveFocusToEditor = Notification.Name(rawValue: "AppDelegate/MoveFocusToEditor")
  static let DeleteNote = Notification.Name(rawValue: "AppDelegate/DeleteNote")
  static let DeleteNoteImmediately = Notification.Name(rawValue: "AppDelegate/DeleteNoteImmediately")
  static let PutBackNote = Notification.Name(rawValue: "AppDelegate/PutBackNote")
  static let EmptyTrash = Notification.Name(rawValue: "AppDelegate/EmptyTrash")
  static let ActualSize = Notification.Name(rawValue: "AppDelegate/ActualSize")
  static let ZoomIn = Notification.Name(rawValue: "AppDelegate/ZoomIn")
  static let ZoomOut = Notification.Name(rawValue: "AppDelegate/ZoomOut")
}
