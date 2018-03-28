//
//  NodeInfo.swift
//  Annay
//
//  Created by Koji Murata on 2018/03/28.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation

struct NodeInfo: Codable {
  var index: Int
  var isDeleted: Bool
  
  init(node: NodeModel) {
    index = node.index
    isDeleted = node.isDeleted
  }
}
