//
//  NodeModel.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/11.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import RealmSwift
import Cocoa

extension NSNotification.Name {
  static let NoteSelected = NSNotification.Name(rawValue: "NodeModel/NoteSelected")
}

final class NodeModel: Object {
  @objc dynamic var id = UUID().uuidString
  @objc dynamic var name = ""
  @objc dynamic var isDirectory = true
  
  @objc dynamic var body: String?
  
  func setBody(_ body: String?) {
    self.body = body
    let markdownName = body?.components(separatedBy: CharacterSet.newlines)[0] ?? Localized("New Note")
    name = markdownName.replacingOccurrences(of: "^#+ ", with: "", options: .regularExpression)
  }
  
  @objc dynamic var parent: NodeModel?
  let descendants = List<NodeModel>()
  @objc dynamic var index = 0
  @objc dynamic var isDeleted = false
  
  override static func primaryKey() -> String? {
    return "id"
  }
  
  private let children = LinkingObjects(fromType: NodeModel.self, property: "parent")
  var sortedChildren: Results<NodeModel> { return children.filter("isDeleted = %@", false).sorted(byKeyPath: "index", ascending: false) }
  
  static var deleted: Results<NodeModel> { return Realm.instance.objects(NodeModel.self).filter("isDeleted = %@", true) }

  static func node(for id: String) -> NodeModel? {
    return Realm.instance.object(ofType: NodeModel.self, forPrimaryKey: id)
  }
}

extension NodeModel {
  func selected() {
    if !isDirectory {
      NotificationCenter.default.post(name: .NoteSelected, object: self)
    }
  }
  
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
  
  private func setParent(_ parent: NodeModel) {
    self.parent = parent
    parent.setAsAncestor(descendant: self)
  }
  
  private func setAsAncestor(descendant: NodeModel) {
    descendants.append(descendant)
    parent?.setAsAncestor(descendant: descendant)
  }

  private static var _root: NodeModel?
  static var root: NodeModel {
    if let root = _root { return root }
    
    let root: NodeModel
    if let rootId = rootId,
      let tmp = NodeModel.node(for: rootId) {
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
