//
//  PreferenceManager.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/03/06.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift

final class PreferenceManager {
  private struct Key {
    static let DirectoryUrl = "PreferenceManager/DirectoryUrl"
  }
  
  static let shared = PreferenceManager()
  
  var generalUrl: URL { return directoryUrl.value.appendingPathComponent("general.yml") }
  var shortcutUrl: URL { return directoryUrl.value.appendingPathComponent("shortcut.yml") }
  var styleSheetsUrl: URL { return directoryUrl.value.appendingPathComponent("stylesheets", isDirectory: true) }
  
  let directoryUrl: Variable<URL>
  
  private static var defaultDirectoryUrl: URL { return  FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".annay", isDirectory: true) }
  
  private init() {
    directoryUrl = Variable<URL>(UserDefaults.standard.url(forKey: Key.DirectoryUrl) ?? PreferenceManager.defaultDirectoryUrl)
    try! FileManager.default.createDirectoryIfNeeded(url: directoryUrl.value)
    
    DispatchQueue.main.async {
      _ = self.directoryUrl.asObservable().subscribe(onNext: { (url) in
        try! FileManager.default.createDirectoryIfNeeded(url: url)
        UserDefaults.standard.set(url, forKey: Key.DirectoryUrl)
        UserDefaults.standard.synchronize()
        GeneralPreference.shared.reload()
        ShortcutPreference.shared.reload()
      })
    }
  }
}
