//
//  SpotlightDataStore.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/20.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation

final class SpotlightDataStore {
  static let shared = SpotlightDataStore()
  
  private let userDefault = UserDefaults(suiteName: "group.koji.murata.MarkDownEditor")!
  
  private init() {}
  
  func set(id: String, body: String) {
    userDefault.set(body, forKey: id)
    userDefault.synchronize()
  }
  
  func body(for id: String) -> String? {
    return userDefault.string(forKey: id)
  }
}
