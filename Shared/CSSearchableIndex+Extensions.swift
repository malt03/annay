//
//  CSSearchableIndex+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/20.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import CoreSpotlight

extension CSSearchableIndex {
  func deleteSearchableItemsWithDataStore(with identifiers: [String]) {
    HtmlDataStore.shared.remove(ids: identifiers)
    deleteSearchableItems(withIdentifiers: identifiers, completionHandler: nil)
  }
}
