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
  private static var prepared = false
  
  static func prepare() {
    if prepared { return }
    prepared = true
    NodeModel.createFirstDirectoryIfNeeded()
  }
  
  static var instance: Realm {
    prepare()
    return try! Realm(configuration: configuration)
  }
  
  private static var configuration: Realm.Configuration {
    let fileUrl = directory.appendingPathComponent("default.realm")
    return Realm.Configuration(fileURL: fileUrl, encryptionKey: encryptionKey, deleteRealmIfMigrationNeeded: true)
  }
  
  private static var encryptionKey: Data {
    let workspace = try! WorkspaceModel.selected.value()
    if let encryptionKey = encryptionKeys[workspace] { return encryptionKey }
    var savedKeyArray = [UInt8](repeating: 0, count: 32)
    var applicationKeyArray = [UInt8](repeating: 0, count: 32)
    savedKey.copyBytes(to: &savedKeyArray, count: 32)
    applicationKey.copyBytes(to: &applicationKeyArray, count: 32)
    let key = Data(bytes: savedKeyArray + applicationKeyArray)
    encryptionKeys[workspace] = key
    return key
  }
  
  private static var encryptionKeys = [WorkspaceModel: Data]()
  
  private static var applicationKey: Data {
    return Data(base64Encoded: "30nUkxK0xrcWu5/PQTtynETnHuoZVGGldnxibpKUeH4=")!
  }
  
  private static var savedKey: Data {
    let fileUrl = directory.appendingPathComponent("secretKey")
    if let key = try? Data(contentsOf: fileUrl) {
      return key
    } else {
      let key = createRandomKey()
      try! key.write(to: fileUrl)
      return key
    }
  }
  
  private static func createRandomKey() -> Data {
    var key = Data(count: 32)
    _ = key.withUnsafeMutableBytes { (bytes) in
      SecRandomCopyBytes(kSecRandomDefault, 32, bytes)
    }
    return key
  }
  
  private static var directory: URL {
    return (try! WorkspaceModel.selected.value()).url.value
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
