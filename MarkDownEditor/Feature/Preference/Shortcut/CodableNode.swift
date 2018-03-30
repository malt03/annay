//
//  CodableNode.swift
//  Annay
//
//  Created by Koji Murata on 2018/03/12.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation

final class CodableNode: Codable, Equatable {
  static func == (lhs: CodableNode, rhs: CodableNode) -> Bool {
    return lhs.nodeId == rhs.nodeId
  }
  
  private let nodeId: String
  
  private(set) lazy var node: NodeModel? = {
    return NodeModel.node(for: nodeId)
  }()
  
  init(node: NodeModel) {
    nodeId = node.id
    self.node = node
  }
}
