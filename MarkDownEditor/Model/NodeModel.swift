//
//  NodeModel.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/11.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import RealmSwift
import Cocoa
import RxSwift
import CoreSpotlight

final class NodeModel: Object {
  private static var trashId: String { return "trash" }
  
  @objc dynamic var id = UUID().uuidString
  @objc dynamic var name = ""
  @objc dynamic var isDirectory = true
  
  @objc dynamic var body: String?
  
  @objc dynamic var parent: NodeModel?
  let descendants = List<NodeModel>()
  @objc dynamic var index = 0
  @objc dynamic var createdAt = Date()
  @objc dynamic var isDeleted = false
  @objc dynamic var deletedAt: Date?
  
  func setBody(_ body: String?) {
    self.body = body
    let nameFromBody = body?.components(separatedBy: CharacterSet.newlines)[safe: 0]?.trimmingCharacters(in: .whitespacesAndNewlines)
    var markdownName = nameFromBody ?? Localized("New Note")
    if markdownName == "" { markdownName = Localized("New Note") }
    name = markdownName.replacingOccurrences(of: "^#+ ", with: "", options: .regularExpression)
    
    updateSpotlight()
  }
  
  func updateCheckbox(content: String, index: Int, isChecked: Bool) {
    if isDirectory { return }
    guard let body = body, let range = body.ranges(of: content)[safe: index] else { return }
    let from = isChecked ? "[ ]" : "[x]"
    let to = isChecked ? "[x]" : "[ ]"
    Realm.transaction { _ in
      self.setBody(body.replacingOccurrences(of: from, with: to, options: [], range: range))
    }
  }
  
  override static func primaryKey() -> String? {
    return "id"
  }
  
  var path: String {
    return ancestors.reversed().map { $0.name }.joined(separator: "/")
  }
  
  override class func ignoredProperties() -> [String] {
    return ["sortedChildren"]
  }
  
  private let children = LinkingObjects(fromType: NodeModel.self, property: "parent")
  func sortedChildren(query: String?) -> Results<NodeModel> {
    if id == NodeModel.trashId { return NodeModel.deleted }
    let result = children.filter("isDeleted = %@ and index >= %@", false, 0).sorted(by: ["index", "createdAt"])
    if let query = query {
      return result.filter("body contains %@ or any descendants.body contains %@", query, query)
    }
    return result
  }
  
  var sortedDirectoryChildren: Results<NodeModel> {
    return children.filter("isDeleted = %@ and index >= %@ and isDirectory = %@", false, 0, true).sorted(by: ["index", "createdAt"])
  }
  
  var ancestors: [NodeModel] {
    guard let parent = parent else { return [] }
    return [parent] + parent.ancestors
  }
  
  static var deleted: Results<NodeModel> {
    return Realm.instance.objects(NodeModel.self)
      .filter("isDeleted = %@ and index >= %@", true, 0)
      .sorted(byKeyPath: "deletedAt")
  }

  static func node(for id: String, for workspace: WorkspaceModel = WorkspaceModel.selected.value) -> NodeModel? {
    return Realm.instance(for: workspace).object(ofType: NodeModel.self, forPrimaryKey: id)
  }
  
  static func roots(query: String?, for workspace: WorkspaceModel = WorkspaceModel.selected.value) -> Results<NodeModel> {
    let result = Realm.instance(for: workspace).objects(NodeModel.self)
      .filter("parent = nil and id != %@ and index >= %@ and isDeleted = %@", trashId, 0, false)
      .sorted(by: ["index", "createdAt"])
    if let query = query {
      return result.filter("any descendants.body contains %@", query)
    }
    return result
  }
  
  static func search(query: String?) -> Results<NodeModel> {
    let result = Realm.instance.objects(NodeModel.self)
    guard let query = query else { return result.empty }
    if query == "" { return result.empty }
    return result.filter("isDirectory = false and name contains[c] %@", query).sorted(byKeyPath: "name")
  }
  
  static var selectedNode: Variable<NodeModel?> = {
    let selectedNode = Variable<NodeModel?>(nil)
    _ = WorkspaceModel.selected.asObservable().map { (workspace) -> NodeModel? in
      guard let id = workspace.selectedNodeId else { return nil }
      return Realm.instance.object(ofType: NodeModel.self, forPrimaryKey: id)
    }.bind(to: selectedNode)
    _ = selectedNode.asObservable().subscribe(onNext: { (node) in
      WorkspaceModel.selected.value.selectedNodeId = node?.id
    })
    return selectedNode
  }()
  
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
    if !isDirectory {
      NodeModel.selectedNode.value = self
    }
  }
  
  static func createFirstDirectoryIfNeeded() {
    if Realm.instance.objects(NodeModel.self).count == 0 {
      createDirectory(name: Localized("Notes"), parent: nil)
    }
  }
  
  @discardableResult
  static func createDirectory(name: String = Localized("New Directory"), parent: NodeModel?) -> NodeModel {
    let node = NodeModel()
    Realm.transaction { (realm) in
      node.name = name
      if let parent = parent {
        node.index = (parent.sortedChildren(query: nil).last?.index ?? -1) + 1
        node.setParent(parent)
      } else {
        node.index = (roots(query: nil).last?.index ?? -1) + 1
      }
      realm.add(node)
    }
    return node
  }
  
  static func createNote(name: String = Localized("New Note"), in directory: NodeModel) -> NodeModel {
    let node = NodeModel()
    Realm.transaction { (realm) in
      node.name = name
      node.index = (directory.sortedChildren(query: nil).last?.index ?? -1) + 1
      node.isDirectory = false
      node.setParent(directory)
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
    if hasDeletedAncestor { return false }
    isDeleted = false
    deletedAt = nil
    return true
  }
  
  var hasDeletedAncestor: Bool {
    guard let parent = parent else { return false }
    if parent.isDeleted { return true }
    return parent.hasDeletedAncestor
  }
  
  static func emptyTrash() {
    Realm.transaction { (realm) in
      let deletedNodes = realm.objects(NodeModel.self).filter("isDeleted = %@", true)
      for node in deletedNodes {
        if node.isInvalidated { continue }
        realm.delete(node.descendants)
      }
      realm.delete(deletedNodes)
    }
  }
  
  func setParent(_ parent: NodeModel?) {
    self.parent?.removeFromDescendants(descendant: self)
    for descendant in descendants { self.parent?.removeFromDescendants(descendant: descendant) }
    self.parent = parent
    parent?.setAsAncestor(descendant: self)
    for descendant in descendants { parent?.setAsAncestor(descendant: descendant) }
  }
  
  private func removeFromDescendants(descendant: NodeModel) {
    if let index = descendants.index(of: descendant) {
      descendants.remove(at: index)
    }
    parent?.removeFromDescendants(descendant: descendant)
  }
  
  private func setAsAncestor(descendant: NodeModel) {
    descendants.append(descendant)
    parent?.setAsAncestor(descendant: descendant)
  }
}

extension NodeModel: NSPasteboardWriting {
  func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
    if isDirectory { return [.nodeModel] }
    return [.nodeModel, .string]
  }
  
  func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
    switch type {
    case .nodeModel: return id
    case .string:    return body
    default:         return nil
    }
  }
}

extension NodeModel: NSFilePromiseProviderDelegate {
  func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
    return name
  }
  
  func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL, completionHandler: @escaping (Error?) -> Void) {
    do {
      try write(to: url)
    } catch {
      completionHandler(error)
    }
    completionHandler(nil)
  }
  
  private func write(to url: URL) throws {
    if isDirectory {
      try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
      for child in sortedChildren(query: nil) {
        try child.write(to: url.appendingPathComponent(child.name))
      }
    } else {
      try (body?.data(using: .utf8) ?? Data()).write(to: url.appendingPathExtension("md"))
    }
  }
}

// スポットライト
extension NodeModel {
  private func updateSpotlight() {
    if isDirectory { return }
    let attribute = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
    attribute.title = name
    attribute.textContent = body
    let item = CSSearchableItem(uniqueIdentifier: id, domainIdentifier: nil, attributeSet: attribute)
    CSSearchableIndex.default().indexSearchableItems([item], completionHandler: nil)
  }
}
