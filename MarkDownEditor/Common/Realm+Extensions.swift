//
//  Realm+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/10.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import RealmSwift
import Foundation

extension Realm {
  static var instance: Realm {
    return try! Realm()
  }
  
  private static var writingInstance: Realm?
  
  static func transaction(_ block: (_ realm: Realm) throws -> Void) rethrows {
    if let realm = writingInstance, realm.isInWriteTransaction {
      try! block(realm)
    } else {
      let realm = instance
      writingInstance = realm
      try! realm.write { try block(realm) }
      writingInstance = nil
    }
  }
  
  static func add(_ object: Object, update: Bool = false) {
    transaction { $0.add(object, update: update) }
  }
}
