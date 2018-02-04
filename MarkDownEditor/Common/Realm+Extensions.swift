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
    return try! Realm(configuration: configuration(for: WorkspaceModel.selected.value))
  }
  
  static func refreshInstance(for workspace: WorkspaceModel) {
    let realm = try! Realm(configuration: configuration(for: WorkspaceModel.selected.value))
    realm.invalidate()
    realm.refresh()
  }
  
  private static func configuration(for workspace: WorkspaceModel) -> Realm.Configuration {
    let fileUrl = directory(for: workspace).realmFile
    return Realm.Configuration(fileURL: fileUrl, encryptionKey: encryptionKey(for: workspace), deleteRealmIfMigrationNeeded: true)
  }
  
  private static func encryptionKey(for workspace: WorkspaceModel) -> Data {
    if let encryptionKey = encryptionKeys[workspace] { return encryptionKey }
    var savedKeyArray = [UInt8](repeating: 0, count: 32)
    var applicationKeyArray = [UInt8](repeating: 0, count: 32)
    savedKey(for: workspace).copyBytes(to: &savedKeyArray, count: 32)
    applicationKey.copyBytes(to: &applicationKeyArray, count: 32)
    let key = Data(bytes: savedKeyArray + applicationKeyArray)
    encryptionKeys[workspace] = key
    return key
  }
  
  private static var encryptionKeys = [WorkspaceModel: Data]()
  
  private static var applicationKey: Data {
    return Data(base64Encoded: "30nUkxK0xrcWu5/PQTtynETnHuoZVGGldnxibpKUeH4=")!
  }
  
  private static func savedKey(for workspace: WorkspaceModel) -> Data {
    let fileUrl = directory(for: workspace).secretKeyFile
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
  
  private static func directory(for workspace: WorkspaceModel) -> URL {
    return WorkspaceModel.selected.value.workspaceDirectory
  }
  
  static func transaction(_ block: (_ realm: Realm) -> Void) {
    let realm = instance
    try! realm.write { block(realm) }
    WorkspaceModel.selected.value.update()
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
