//
//  FileManager+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/03.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation

extension FileManager {
  var applicationSupport: URL {
    let supportDirectory = urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    return supportDirectory.appendingPathComponent(Bundle.main.bundleIdentifier!, isDirectory: true)
  }
  
  func createDirectoryIfNeeded(url: URL) throws {
    if !fileExists(atPath: url.path) {
      try createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }
  }
  
  func copyAllItem(in parent: URL, to url: URL) throws {
    if !fileExists(atPath: parent.path) { return }
    for child in try contentsOfDirectory(atPath: parent.path) {
      let copyUrl = url.appendingPathComponent(child)
      if fileExists(atPath: copyUrl.path) { try removeItem(at: copyUrl) }
      try copyItem(at: parent.appendingPathComponent(child), to: copyUrl)
    }
  }
}
