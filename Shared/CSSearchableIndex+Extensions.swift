//
//  CSSearchableIndex+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/20.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import CoreSpotlight

extension CSSearchableIndex {
  func deleteSearchableItemsWithDataStore(nodeIds: [String], workspaceId: String) {
    HtmlDataStore.shared.remove(nodeIds: nodeIds)
    let identifiers = nodeIds.map { CSSearchableIndex.identifier(nodeId: $0, workspaceId: workspaceId) }
    deleteSearchableItems(withIdentifiers: identifiers, completionHandler: nil)
  }
  
  func deleteSearchableItemsWithDataStore(with identifiers: [String]) {
    let nodeIds = identifiers.flatMap { $0.split(separator: "/").last.flatMap { String($0) } }
    HtmlDataStore.shared.remove(nodeIds: nodeIds)
    deleteSearchableItems(withIdentifiers: identifiers, completionHandler: nil)
  }
  
  static func identifier(nodeId: String, workspaceId: String) -> String {
    return "\(workspaceId)/\(nodeId)"
  }
}
