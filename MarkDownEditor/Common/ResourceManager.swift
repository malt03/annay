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
  
  static func save(data: Data, fileExtension: String, in workspace: WorkspaceModel = WorkspaceModel.selectedValue) throws -> URL {
    let fileName = UUID().uuidString + "." + fileExtension

    let workspaceSourceDirectory = workspace.directoryUrl.resourceDirectory
    
    var url = URL(fileURLWithPath: "/")
    
    try BookmarkManager.shared.getBookmarkedURL(workspaceSourceDirectory, fallback: { workspaceSourceDirectory }) { (bookmarkedURL) in
      try FileManager.default.createDirectoryIfNeeded(url: url)
      url = bookmarkedURL.appendingPathComponent(fileName)
      try data.write(to: url)
    }

    return url
  }
}
