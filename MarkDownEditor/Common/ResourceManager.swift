//
//  ResourceManager.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/09.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class ResourceManager {
  private init() {}
  
  static var resourceUrl: URL { return FileManager.default.applicationSupport.appendingPathComponent("resource", isDirectory: true) }
  
  static func prepare() {
    do {
      try FileManager.default.createDirectoryIfNeeded(url: resourceUrl)
    } catch {
      NSAlert(error: error).runModal()
    }
  }
  
  static func save(data: Data, fileExtension: String, in workspace: WorkspaceModel = WorkspaceModel.selectedValue) throws -> URL {
    let fileName = UUID().uuidString + "." + fileExtension

    let workspaceSourceDirectory = workspace.directoryUrl.resourceDirectory
    try FileManager.default.createDirectoryIfNeeded(url: workspaceSourceDirectory)
    try data.write(to: workspaceSourceDirectory.appendingPathExtension(fileName))

    let url = resourceUrl.appendingPathComponent(fileName)
    try data.write(to: url)
    return url
  }
  
  static func copy(from directory: URL) throws {
    try FileManager.default.copyAllItem(in: directory, to: resourceUrl)
  }
}
