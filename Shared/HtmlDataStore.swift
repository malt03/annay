//
//  HtmlDataStore.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/20.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation

final class HtmlDataStore {
  private struct Key {
    static func Html(for id: String) -> String { return "HtmlDataStore/Html/\(id)" }
  }
  
  static let shared = HtmlDataStore()
  
  private let userDefault = UserDefaults(suiteName: "group.koji.murata.MarkDownEditor")!
  
  private init() {}
  
  func set(id: String, html: String) {
    userDefault.set(html, forKey: Key.Html(for: id))
    userDefault.synchronize()
  }
  
  func remove(ids: [String]) {
    for id in ids {
      userDefault.removeObject(forKey: Key.Html(for: id))
    }
    userDefault.synchronize()
  }
  
  func html(for id: String) -> String? {
    return userDefault.string(forKey: Key.Html(for: id))
  }
}
