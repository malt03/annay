//
//  DirectoryInfo.swift
//  ModelExample
//
//  Created by Koji Murata on 2018/03/23.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation
import RealmSwift

struct DirectoryInfo: Codable {
  var children: [String: NodeInfo]
  var lastUpdatedAt: Date
  var name: String
  
  init(directoryUrl: URL) {
    if let data = try? Data(contentsOf: directoryUrl.infoFile), let info = try? JSONDecoder().decode(DirectoryInfo.self, from: data) {
      self = info
    } else {
      children = [:]
      lastUpdatedAt = Date(timeIntervalSince1970: 0)
      name = Localized("New Directory")
    }
  }
  
  init(children: LinkingObjects<NodeModel>, directory: NodeModel) {
    self.children = children.reduce([:], { (result, node) in
      var tmp = result
      tmp[node.id] = NodeInfo(node: node)
      return tmp
    })
    lastUpdatedAt = directory.lastUpdatedAt
    name = directory.name
  }
  
  func write(to directoryUrl: URL) throws {
    try JSONEncoder().encode(self).write(to: directoryUrl.infoFile)
  }
}
