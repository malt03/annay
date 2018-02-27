//
//  HtmlDataStore.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/20.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation
import CoreSpotlight

extension Notification.Name {
  static func StoredHtmlData(nodeId: String) -> Notification.Name { return Notification.Name("HtmlDataStore/StoredHtmlData/\(nodeId)") }
}

final class HtmlDataStore {
  private struct Key {
    static func Html(for nodeId: String) -> String { return "HtmlDataStore/Html/\(nodeId)" }
  }
  
  static let shared = HtmlDataStore()
  
  private let userDefault = UserDefaults(suiteName: "group.koji.murata.MarkDownEditor")!
  
  private init() {}
  
  func set(nodeId: String, html: String) {
    print("set", nodeId)
    userDefault.set(html, forKey: Key.Html(for: nodeId))
    
//    for key in userDefault.dictionaryRepresentation().keys {
//      userDefault.removeObject(forKey: key)
//    }

    userDefault.synchronize()
    NotificationCenter.default.post(name: .StoredHtmlData(nodeId: nodeId), object: nil)
  }
  
  func remove(nodeIds: [String]) {
    for id in nodeIds {
      userDefault.removeObject(forKey: Key.Html(for: id))
    }
    userDefault.synchronize()
  }
  
  func html(for nodeId: String) -> String? {
    return userDefault.string(forKey: Key.Html(for: nodeId))
  }
}
