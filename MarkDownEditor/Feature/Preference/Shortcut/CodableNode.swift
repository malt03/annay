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
    return lhs.nodeId == rhs.nodeId && lhs.workspaceId == rhs.workspaceId
  }
  
  private let nodeId: String
  private let workspaceId: String
  
  private(set) lazy var workspace = WorkspaceModel.space(uniqId: workspaceId)
  private(set) lazy var node: NodeModel? = {
    guard let workspace = workspace else { return nil }
    return NodeModel.node(for: nodeId, for: workspace)
  }()
  
  init(node: NodeModel, workspace: WorkspaceModel) {
    nodeId = node.id
    workspaceId = workspace.uniqId
    self.node = node
    self.workspace = workspace
  }
}
