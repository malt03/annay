//
//  SavableInUserDefaults.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/17.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation

protocol SavableInUserDefaults {
  var dictionary: [String: Any] { get }
  init?(dictionary: [String: Any])
}

extension UserDefaults {
  func set(_ value: SavableInUserDefaults, forKey key: String) {
    set(value.dictionary, forKey: key)
  }
  
  func set<T: SavableInUserDefaults>(_ value: [T], forKey key: String) {
    set(value.map { $0.dictionary }, forKey: key)
  }
  
  func savableObject<T: SavableInUserDefaults>(forKey key: String) -> T? {
    guard let dictionary = dictionary(forKey: key) else { return nil }
    return T(dictionary: dictionary)
  }

  func savableObjectArray<T: SavableInUserDefaults>(forKey key: String) -> [T]? {
    guard let array = array(forKey: key) as? [[String: Any]] else { return nil }
    return array.compactMap { T(dictionary: $0) }
  }
}
