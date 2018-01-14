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
  private static var trashId: String { return "trash" }
  
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
  @objc dynamic var deletedAt: Date?
  
  override static func primaryKey() -> String? {
    return "id"
  }
  
  private let children = LinkingObjects(fromType: NodeModel.self, property: "parent")
  var sortedChildren: Results<NodeModel> {
    if id == NodeModel.trashId { return NodeModel.deleted }
    return children.filter("isDeleted = %@", false).sorted(byKeyPath: "index")
  }
  
  static var deleted: Results<NodeModel> { return Realm.instance.objects(NodeModel.self).filter("isDeleted = %@", true).sorted(byKeyPath: "deletedAt") }

  static func node(for id: String) -> NodeModel? {
    return Realm.instance.object(ofType: NodeModel.self, forPrimaryKey: id)
  }
  
  static var roots: Results<NodeModel> {
    let result = Realm.instance.objects(NodeModel.self).filter("parent = nil and id != %@", trashId).sorted(byKeyPath: "index")
    if result.count == 0 {
      createDirectory(name: Localized("Notes"), parent: nil, index: 0)
    }
    return result
  }
  
  var isRoot: Bool {
    return parent == nil
  }
  
  var isTrash: Bool {
    return id == NodeModel.trashId
  }
  
  private static var _trash: NodeModel?
  
  static var trash: NodeModel {
    if let trash = _trash { return trash }
    
    let trash: NodeModel
    if let _trash = Realm.instance.object(ofType: NodeModel.self, forPrimaryKey: trashId) {
      trash = _trash
    } else {
      trash = NodeModel()
      trash.name = Localized("Trash")
      trash.id = trashId
      trash.isDirectory = true
      trash.save()
    }
    _trash = trash
    return trash
  }
}

extension NodeModel {
  func selected() {
    if !isDirectory && !isDeleted {
      NotificationCenter.default.post(name: .NoteSelected, object: self)
    }
  }
  
  @discardableResult
  static func createDirectory(name: String = Localized("New Directory"), parent: NodeModel?, index: Int? = nil) -> NodeModel {
    let node = NodeModel()
    Realm.transaction { (realm) in
      node.name = name
      let i: Int
      if let index = index {
        i = index
      } else {
        if let parent = parent {
          node.setParent(parent)
          i = (parent.sortedChildren.last?.index ?? -1) + 1
        } else {
          i = (roots.last?.index ?? -1) + 1
        }
      }
      node.index = i
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
      node.index = (directory.sortedChildren.last?.index ?? -1) + 1
      realm.add(node)
    }
    return node
  }
  
  func delete() -> Bool {
    if isDeleted { return false }
    isDeleted = true
    deletedAt = Date()
    return true
  }
  
  func putBack() -> Bool {
    if !isDeleted { return false }
    isDeleted = false
    deletedAt = nil
    return true
  }
  
  static func emptyTrash() {
    Realm.transaction { (realm) in
      realm.delete(realm.objects(NodeModel.self).filter("isDeleted = %@", true))
    }
  }
  
  private func setParent(_ parent: NodeModel) {
    self.parent = parent
    parent.setAsAncestor(descendant: self)
  }
  
  private func setAsAncestor(descendant: NodeModel) {
    descendants.append(descendant)
    parent?.setAsAncestor(descendant: descendant)
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
