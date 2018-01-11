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
  func applicationDidFinishLaunching(_ notification: Notification) {
    Realm.prepare()
  }
  
  @IBAction private func resetRealm(_ sender: NSMenuItem) {
    Realm.transaction { (realm) in
      realm.deleteAll()
    }
  }
}
