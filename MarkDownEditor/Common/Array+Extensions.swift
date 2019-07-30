//
//  Array+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/15.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation
import RealmSwift

extension Array where Element: Hashable {
  var uniq: [Element] {
    return Array(Set(self))
  }
}

extension Array where Element: Equatable {
  func index(of object: Element) -> Int? {
    return firstIndex { $0 == object }
  }
  
  @discardableResult
  mutating func remove(object: Element) -> Int? {
    guard let index = index(of: object) else { return nil }
    remove(at: index)
    return index
  }
  
  @discardableResult
  mutating func remove(objects: [Element]) -> [Int] {
    return objects.compactMap { remove(object: $0) }
  }
}

extension Array where Element == NodeModel {
  var deletingDescendants: [NodeModel] {
    return filter { (node) in
      for ancestor in node.ancestors {
        if contains(ancestor) { return false }
      }
      return true
    }
  }
  
  var hasSameParent: Bool {
    if count == 0 { return false }
    guard let sameParentId = self[0].parent?.id else { return false }
    for node in self {
      guard let parent = node.parent else {
        return false
      }
      if node.isDeleted {
        return false
      }
      if parent.id != sameParentId {
        return false
      }
    }
    return true
  }
}

extension Array where Element == URL {
  var creatableRootNodesCount: Int {
    return filter({ $0.isDirectory || $0.isConformsToUTI("public.plain-text") }).count
  }
  
  @discardableResult
  func createNodes(parent: NodeModel?, startIndex: Int, realm: Realm, workspace: WorkspaceModel) throws -> [NodeModel] {
    var index = startIndex
    return try compactMap { (url) -> NodeModel? in
      let isDirectory = url.isDirectory
      if !isDirectory && !url.isConformsToUTI("public.plain-text") { return nil }
      
      let node: NodeModel
      if isDirectory {
        node = try NodeModel.createDirectory(name: url.name, parent: parent)
      } else {
        guard let parent = parent else { return nil }
        node = NodeModel.createNote(in: parent)
        node.setBody(try String(contentsOfFile: url.path))
      }
      node.index = index
      realm.add(node)

      index += 1

      if isDirectory {
        try FileManager.default.contentsOfDirectory(atPath: url.path).map {
          url.appendingPathComponent($0)
        }.createNodes(parent: node, startIndex: 0, realm: realm, workspace: workspace)
      }
      try node.save()
      return node
    }
  }
}
