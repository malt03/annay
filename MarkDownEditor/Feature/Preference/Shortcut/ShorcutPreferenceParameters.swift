//
//  ShorcutPreferenceParameters.swift
//  Annay
//
//  Created by Koji Murata on 2018/03/11.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation
import Magnet

struct ShortcutPreferenceParameters: Codable {
  private let keyCode: Int
  private let modifiers: Int
  
  private let nodeId: String
  private let workspaceId: String
  
  func get() -> (WorkspaceModel, NodeModel)? {
    guard
      let workspace = WorkspaceModel.space(uniqId: workspaceId),
      let node = NodeModel.node(for: nodeId, for: workspace)
      else { return nil }
    return (workspace, node)
  }
  
  var keyCombo: KeyCombo? { return KeyCombo(keyCode: keyCode, carbonModifiers: modifiers) }
  
  init(keyCombo: KeyCombo, node: NodeModel, workspace: WorkspaceModel) {
    keyCode = keyCombo.keyCode
    modifiers = keyCombo.modifiers
    nodeId = node.id
    workspaceId = workspace.uniqId
  }
}
