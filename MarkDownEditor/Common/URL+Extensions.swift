//
//  URL+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/26.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation

extension URL {
  var replacingHomePath: String {
    return path.replacingHomePathToTilde
  }
  
  var isDirectory: Bool {
    var isDirectory = ObjCBool(booleanLiteral: false)
    if !FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) { return false }
    return isDirectory.boolValue
  }
  
  var isWorkspace: Bool {
    if isDirectory { return false }
    let uti = (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier
    return uti == "com.annay.workspace"
  }
  
  func isEqualIgnoringLastSlash(_ url: URL) -> Bool {
    return appendingPathComponent("x") == url.appendingPathComponent("x")
  }
  
  var name: String {
    return deletingPathExtension().lastPathComponent
  }
  
  var realmFile: URL {
    return appendingPathComponent("default.realm")
  }
  
  var secretKeyFile: URL {
    return appendingPathComponent("secretKey")
  }
  
  var resourceDirectory: URL {
    return appendingPathComponent("resource", isDirectory: true)
  }
  
  var uti: CFString {
    return ((try? resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier ?? "") ?? "") as CFString
  }
  
  func isConformsToUTI(_ uti: String) -> Bool {
    return UTTypeConformsTo(self.uti, uti as CFString)
  }
}
