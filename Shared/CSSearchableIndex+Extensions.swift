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
    let identifiers = nodeIds.map { CSSearchableIndex.identifier(nodeId: $0, workspaceId: workspaceId) }
    deleteSearchableItemsWithDataStore(with: identifiers)
  }
  
  func deleteSearchableItemsWithDataStore(with identifiers: [String]) {
    HtmlDataStore.shared.remove(ids: identifiers)
    deleteSearchableItems(withIdentifiers: identifiers, completionHandler: nil)
  }
  
  static func identifier(nodeId: String, workspaceId: String) -> String {
    return "\(workspaceId)/\(nodeId)"
  }
}
