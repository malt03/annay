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
  private let children = LinkingObjects(fromType: NodeModel.self, property: "parent")
  var sortedChildren: Results<NodeModel> { return children.sorted(byKeyPath: "index", ascending: false) }
  let descendants = List<NodeModel>()
  @objc dynamic var index = 0
  
  private func setParent(_ parent: NodeModel) {
    self.parent = parent
    parent.setAsAncestor(descendant: self)
  }
  
  private func setAsAncestor(descendant: NodeModel) {
    descendants.append(descendant)
    parent?.setAsAncestor(descendant: descendant)
  }
  
  override static func primaryKey() -> String? {
    return "id"
  }
}

extension NodeModel {
  static func createDirectory(name: String = Localized("New Directory"), parent: NodeModel?) -> NodeModel {
    let node = NodeModel()
    Realm.transaction { (realm) in
      node.name = name
      if let parent = parent { node.setParent(parent) }
      node.index = (parent?.sortedChildren.first?.index ?? -1) + 1
      realm.add(node)
    }
    return node
  }
  
  static func createNote(name: String = Localized("New Note"), in directory: NodeModel) -> NodeModel {
    let node = NodeModel()
    Realm.transaction { (realm) in
      node.name = name
      node.isDirectory = false
      node.setParent(directory)
      node.index = (directory.sortedChildren.first?.index ?? -1) + 1
      realm.add(node)
    }
    return node
  }
  
  private static var _root: NodeModel?
  static var root: NodeModel {
    if let root = _root { return root }
    
    let root: NodeModel
    if let rootId = rootId,
      let tmp = Realm.instance.object(ofType: NodeModel.self, forPrimaryKey: rootId) {
      root = tmp
    } else {
      root = createDirectory(name: "", parent: nil)
      rootId = root.id
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
