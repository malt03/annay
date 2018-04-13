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
  
  static private var workspaceUti = "org.annay.workspace"
  static private var folderWorkspaceUti = "org.annay.folderworkspace"
  static var workspaceUtis: Set<String> { return [workspaceUti, folderWorkspaceUti] }
  
  static var workspaceExtension: String { return "annay" }
  static var folderWorkspaceExtension: String { return "annayf" }
  
  var isWorkspaceAsFolder: Bool {
    return uti == URL.folderWorkspaceUti
  }
  
  var isWorkspace: Bool {
    if !isDirectory { return false }
    return URL.workspaceUtis.contains(uti)
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
  
  var uti: String {
    return ((try? resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier ?? "") ?? "")
  }
  
  func isConformsToUTI(_ uti: String) -> Bool {
    return UTTypeConformsTo(self.uti as CFString, uti as CFString)
  }
  
  var infoFile: URL { return appendingPathComponent("info.json") }
}
