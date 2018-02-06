//
//  Array+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/15.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation

extension Array where Element: Equatable {
  func index(of object: Element) -> Int? {
    return index { $0 == object }
  }
  
  @discardableResult
  mutating func remove(object: Element) -> Int? {
    guard let index = index(of: object) else { return nil }
    remove(at: index)
    return index
  }
  
  @discardableResult
  mutating func remove(objects: [Element]) -> [Int] {
    return objects.flatMap { remove(object: $0) }
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
}
