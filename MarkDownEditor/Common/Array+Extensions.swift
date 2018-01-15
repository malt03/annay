//
//  Array+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/15.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation

extension Array where Element == NodeModel {
  var removeChildren: [NodeModel] {
    return filter { (node) in
      guard let parent = node.parent else { return true }
      return !contains(parent)
    }
  }
}
