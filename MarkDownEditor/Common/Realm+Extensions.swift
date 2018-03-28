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
  
  static func transaction(_ block: (_ realm: Realm) throws -> Void) rethrows {
    let realm = instance
    try! realm.write { try block(realm) }
  }
  
  static func add(_ object: Object, update: Bool = false) {
    transaction { $0.add(object, update: update) }
  }
}
