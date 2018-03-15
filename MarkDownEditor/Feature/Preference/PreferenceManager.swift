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
  
  var generalUrl: URL { return directoryUrl.appendingPathComponent("general.yml") }
  var shortcutUrl: URL { return directoryUrl.appendingPathComponent("shortcut.yml") }
  var styleSheetsUrl: URL { return directoryUrl.appendingPathComponent("stylesheets", isDirectory: true) }
  
  private var directoryUrl: URL
  
  private static var defaultDirectoryUrl: URL { return  FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".annay", isDirectory: true) }
  
  private init() {
    directoryUrl = UserDefaults.standard.url(forKey: Key.DirectoryUrl) ?? PreferenceManager.defaultDirectoryUrl
    do {
      try FileManager.default.createDirectoryIfNeeded(url: directoryUrl)
    } catch {
      NSAlert(error: error).runModal()
    }
  }
}
