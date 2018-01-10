//
//  NodeModel.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/11.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import RealmSwift
import Cocoa

final class NodeModel: Object {
  @objc dynamic var id = UUID().uuidString
  @objc dynamic var name = ""
  @objc dynamic var isDirectory = true
  
  @objc dynamic var body: String?
  
  @objc dynamic var parent: NodeModel?
  let children = LinkingObjects(fromType: NodeModel.self, property: "parent").sorted(byKeyPath: "index")
  let descendants = List<NodeModel>()
  @objc dynamic var index = 0
  
  override static func primaryKey() -> String? {
    return "id"
  }
}

extension NodeModel {
  private static var _root: NodeModel?
  static var root: NodeModel {
    if let root = _root { return root }
    
    let root: NodeModel
    if let rootId = rootId,
      let tmp = Realm.instance.object(ofType: NodeModel.self, forPrimaryKey: rootId) {
      root = tmp
    } else {
      root = NodeModel()
      rootId = root.id
      root.save()
    }
    
    _root = root
    return root
  }
}

extension NodeModel {
  private struct Key {
    static let RootId = "NodeModel/RootId"
  }
  
  private static var rootId: String? {
    get { return UserDefaults.standard.string(forKey: Key.RootId) }
    set {
      let ud = UserDefaults.standard
      ud.set(newValue, forKey: Key.RootId)
      ud.synchronize()
    }
  }
}
