//
//  Realm+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/10.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import RealmSwift

extension Realm {
  private static var prepared = false
  
  static func prepare() {
    if prepared { return }
    prepared = true
    Realm.Configuration.defaultConfiguration = Realm.Configuration(deleteRealmIfMigrationNeeded: true)
    NodeModel.createFirstDirectoryIfNeeded()
  }
  
  static var instance: Realm {
    prepare()
    return try! Realm()
  }
  static func transaction(_ block: (_ realm: Realm) -> Void) {
    let realm = instance
    try! realm.write { block(realm) }
  }
  static func add(_ object: Object, update: Bool = false) {
    transaction { $0.add(object, update: update) }
  }
}

extension Object {
  func save() {
    Realm.add(self, update: true)
  }
}
