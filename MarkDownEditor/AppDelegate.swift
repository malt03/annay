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
}

extension Notification.Name {
  static let RevealInSidebar = Notification.Name(rawValue: "AppDelegate/RevealInSidebar")
  static let SelectNextWorkspace = Notification.Name(rawValue: "AppDelegate/SelectNextWorkspace")
  static let SelectPreviousWorkspace = Notification.Name(rawValue: "AppDelegate/SelectPreviousWorkspace")
}
