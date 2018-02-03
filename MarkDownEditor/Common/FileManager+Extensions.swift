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
  
  var applicationTmp: URL {
    return applicationSupport.appendingPathComponent("tmp", isDirectory: true)
  }
  
  func createDirectoryIfNeeded(url: URL) throws {
    if !fileExists(atPath: url.path) {
      try createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }
  }
}
