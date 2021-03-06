//
//  NodeModel.swift
//  ModelExample
//
//  Created by Koji Murata on 2018/03/23.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation
import CoreSpotlight
import RealmSwift
import RxSwift
import RxRelay

final class NodeModel: Object {
  private static var trashId: String { return "trash" }

  @objc private(set) dynamic var id = UUID().uuidString
  @objc private(set) dynamic var workspace: WorkspaceModel?
  
  @objc dynamic var parent: NodeModel?
  @objc dynamic var index = -1
  
  @objc private(set) dynamic var name = ""
  @objc private(set) dynamic var lastUpdatedAt = Date(timeIntervalSince1970: 0)
  
  @objc dynamic var isDirectory = true
  @objc private(set) dynamic var body = ""
  @objc private(set) dynamic var isBodySaved = true
  
  @objc dynamic var isDeleted = false
  @objc private dynamic var deletedAt: Date?
  
  var isDeletedWithParent: Bool {
    if isDeleted { return true }
    return parent?.isDeletedWithParent ?? false
  }
  
  var ancestors: [NodeModel] {
    guard let parent = parent else { return [] }
    return [parent] + parent.ancestors
  }
  
  private let children = LinkingObjects(fromType: NodeModel.self, property: "parent")
  var descendants: [NodeModel] {
    return children + children.flatMap({ $0.descendants })
  }
  
  private func ancestor(targetParent: NodeModel) -> NodeModel? {
    guard let parent = parent else { return nil }
    if parent.id == targetParent.id { return self }
    return parent.ancestor(targetParent: targetParent)
  }

  var path: String {
    return ancestors.reversed().map { $0.name }.joined(separator: "/")
  }
  
  typealias ConfirmUpdateNote = (_ note: NodeModel, _ handler: (_ isUpdate: Bool) throws -> Void) throws -> Void
  
  func sortedChildren(query: String?) -> [NodeModel] {
    if id == NodeModel.trashId { return Array(NodeModel.deleted) }
    if let query = query {
      var ids = Set<String>()
      return Realm.instance.objects(NodeModel.self)
        .filter("workspace = %@ and body contains %@", WorkspaceModel.selectedValue, query)
        .compactMap { $0.ancestor(targetParent: self) }
        .filter {
          if ids.contains($0.id) { return false }
          ids.insert($0.id)
          return true
        }
    } else {
      return Array(
        children.filter("isDeleted = false and index >= 0")
          .sorted(byKeyPath: "index")
      )
    }
  }
  
  static func containsBody(_ body: String, in workspace: WorkspaceModel) -> Bool {
    return Realm.instance.objects(NodeModel.self)
      .filter("workspace = %@ and body contains %@", workspace, body)
      .count > 0
  }

  var url: URL {
    guard let parent = parent else { return workspace!.notesUrl }
    let url = parent.url.appendingPathComponent(id)
    if isDirectory {
      return url
    } else {
      return url.appendingPathExtension("md")
    }
  }

  func updateIndexIfNeeded(confirmUpdateNote: ConfirmUpdateNote, realm: Realm) throws {
    if isDirectory {
      try updateDirectoryIndexIfNeeded(confirmUpdateNote: confirmUpdateNote, realm: realm)
    } else {
      try updateNoteIndexIfNeeded(confirmUpdateNote: confirmUpdateNote)
    }
  }
  
  func move(in node: NodeModel) throws {
    let oldUrl = url
    let oldParent = parent
    parent = node
    workspace = node.workspace
    let newUrl = url
    try BookmarkManager.shared.getBookmarkedURL(oldUrl, fallback: { oldUrl }) { (bookmarkedOldUrl) in
      if FileManager.default.fileExists(atPath: bookmarkedOldUrl.path) {
        try BookmarkManager.shared.getBookmarkedURL(newUrl, fallback: { newUrl }) { (bookmarkedNewUrl) in
          try FileManager.default.moveItem(at: bookmarkedOldUrl, to: bookmarkedNewUrl)
        }
      }
    }
    try oldParent?.save()
    try parent?.save()
  }
  
  func save(reselect: Bool = false) throws {
    try parent?.save()
    
    lastUpdatedAt = Date()
    if isDirectory {
      try saveDirectory()
    } else {
      try saveNote()
      if reselect {
        reselectIfSelected()
      }
    }
  }
  
  func saveWithChildren(reselect: Bool) throws {
    try save(reselect: reselect)
    for child in children {
      try child.saveWithChildren(reselect: reselect)
    }
  }
  
  static func saveAll(for workspace: WorkspaceModel) throws {
    for note in Realm.instance.objects(NodeModel.self).filter("workspace = %@", workspace) {
      try note.save()
    }
  }
  
  static var deleted: Results<NodeModel> {
    return Realm.instance.objects(NodeModel.self)
      .filter("isDeleted = true and workspace = %@ and index >= 0", WorkspaceModel.selectedValue)
      .sorted(byKeyPath: "deletedAt")
  }
  
  static var unsaved: Results<NodeModel> {
    return Realm.instance.objects(NodeModel.self).filter("isBodySaved = false")
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
      Realm.transaction { $0.add(trash) }
    }
    _trash = trash
    return trash
  }

  static func emptyTrash() throws {
    try Realm.transaction { (realm) in
      let deletedNodes = realm.objects(NodeModel.self).filter("isDeleted = true and workspace = %@", WorkspaceModel.selectedValue)
      let parentNodes = deletedNodes.compactMap { $0.parent }.uniq

      let deletedNodeIds: [String] = deletedNodes.flatMap { [$0.id] + $0.descendants.map { $0.id } }
      CSSearchableIndex.default().deleteSearchableItemsWithDataStore(with: deletedNodeIds)
      for node in deletedNodes {
        if node.isInvalidated { continue }
        realm.delete(node.descendants)
        
        try BookmarkManager.shared.getBookmarkedURL(node.url, fallback: { node.url }) { (bookmarkedUrl) in
          if FileManager.default.fileExists(atPath: bookmarkedUrl.path) {
            try FileManager.default.removeItem(at: bookmarkedUrl)
          }
        }
      }
      realm.delete(deletedNodes)
      
      for node in parentNodes { try node.save() }
    }
  }
  
  static func node(for id: String, realm: Realm = .instance) -> NodeModel? {
    return realm.objects(NodeModel.self).filter("id = %@", id).first
  }
  
  static func search(query: String?) -> Results<NodeModel> {
    let result = Realm.instance.objects(NodeModel.self)
    guard let query = query else { return result.empty }
    if query == "" { return result.empty }
    return result.filter("isDirectory = false and name contains[c] %@", query).sorted(byKeyPath: "name")
  }
  
  static func create(id: String, parent: NodeModel, isDirectory: Bool, realm: Realm) -> NodeModel {
    let node = NodeModel()
    node.id = id
    node.workspace = parent.workspace!
    node.parent = parent
    node.isDirectory = isDirectory
    node.index = (parent.sortedChildren(query: nil).last?.index ?? -1) + 1
    realm.add(node)
    return node
  }
  
  var copied: NodeModel {
    let node = NodeModel()
    let keys = ["name", "isDirectory", "body", "isDeleted", "deletedAt"]
    for key in keys {
      node.setValue(value(forKey: key), forKey: key)
    }
    return node
  }
  
  func createCopy(realm: Realm, parent: NodeModel, index: Int) throws {
    let node = copied
    node.parent = parent
    node.workspace = parent.workspace
    node.index = index
    try node.save()
    realm.add(node)
    
    for (index, child) in sortedChildren(query: nil).enumerated() {
      try child.createCopy(realm: realm, parent: node, index: index)
    }
  }
  
  static var selectedNode: BehaviorRelay<NodeModel?> = {
    let selectedNode = BehaviorRelay<NodeModel?>(value: nil)
    _ = WorkspaceModel.selectedObservable.map { $0.selectedNode }.bind(to: selectedNode)
    _ = selectedNode.asObservable().subscribe(onNext: { (node) in
      Realm.transaction { _ in
        WorkspaceModel.selectedValue.selectedNode = node
      }
    })
    return selectedNode
  }()
  
  func select() {
    if isDirectory { return }
    workspace?.select()
    NodeModel.selectedNode.accept(self)
  }
  
  private func reselectIfSelected() {
    if NodeModel.selectedNode.value?.id == id {
      select()
    }
  }
  
  func delete() throws -> Bool {
    if isTrash { return false }
    if isDeletedWithParent { return false }
    isDeleted = true
    deletedAt = Date()
    try saveWithChildren(reselect: true)
    return true
  }
  
  func putBack() throws -> Bool {
    if !isDeleted { return false }
    if hasDeletedAncestor { return false }
    isDeleted = false
    deletedAt = nil
    try save()
    return true
  }
  
  private var hasDeletedAncestor: Bool {
    guard let parent = parent else { return false }
    if parent.isDeleted { return true }
    return parent.hasDeletedAncestor
  }
    
  func deleteImmediately(realm: Realm, workspace: WorkspaceModel) throws {
    let nodeIds = descendants.map { $0.id } + [id]
    CSSearchableIndex.default().deleteSearchableItemsWithDataStore(with: nodeIds)
    try BookmarkManager.shared.getBookmarkedURL(url, fallback: { url }) { (bookmarkedUrl) in
      if FileManager.default.fileExists(atPath: bookmarkedUrl.path) {
        try FileManager.default.removeItem(at: bookmarkedUrl)
      }
    }
    
    realm.delete(descendants)
    realm.delete(self)
  }
  
  func export(in url: URL, type: NodeModelExporter.ExportType, selectAndWriteQueue: inout NodeModelExporter.SelectAndWriteQueue) throws -> URL? {
    return try write(to: url.appendingPathComponent(name), as: type) { (node, url) in
      selectAndWriteQueue.enqueue((node, url))
    }
  }
  
  @discardableResult
  func write(
    to url: URL,
    as type: NodeModelExporter.ExportType,
    selectAndWriteEnqueueHandler: ((NodeModelExporter.QueueItem) -> Void) = { _ in }
  ) throws -> URL? {
    let writeUrl: URL
    if isDirectory {
      try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
      for child in sortedChildren(query: nil) {
        try child.write(to: url.appendingPathComponent(child.name), as: type, selectAndWriteEnqueueHandler: selectAndWriteEnqueueHandler)
      }
      writeUrl = url
    } else {
      switch type {
      case .html:
        guard let html = HtmlDataStore.shared.html(for: id) else {
          selectAndWriteEnqueueHandler((self, url))
          return nil
        }
        if url.pathExtension == "" {
          writeUrl = url.appendingPathExtension("html")
        } else {
          writeUrl = url
        }
        try html.write(to: writeUrl, atomically: true, encoding: .utf8)
      case .text:
        if url.pathExtension == "" {
          writeUrl = url.appendingPathExtension("md")
        } else {
          writeUrl = url
        }
        try (body.data(using: .utf8) ?? Data()).write(to: writeUrl)
      }
    }
    return writeUrl
  }
  
  func prepareDelete() {
    workspace = nil
  }
  
  override class func primaryKey() -> String? {
    return "id"
  }
}

// ノート
extension NodeModel {
  func updateCheckbox(content: String, index: Int, isChecked: Bool) throws {
    if isDirectory { return }
    guard let range = body.ranges(of: content)[safe: index] else { return }
    let from = isChecked ? "[ ]" : "[x]"
    let to = isChecked ? "[x]" : "[ ]"
    try Realm.transaction { _ in
      self.setBody(body.replacingOccurrences(of: from, with: to, options: [], range: range))
      try self.save()
    }
  }
  
  func setBody(_ body: String) {
    isBodySaved = false
    self.body = body
    let nameFromBody = body.components(separatedBy: CharacterSet.newlines)[safe: 0]?.trimmingCharacters(in: .whitespacesAndNewlines)
    var markdownName = nameFromBody ?? Localized("New Note")
    if markdownName == "" { markdownName = Localized("New Note") }
    name = markdownName.replacingOccurrences(of: "^#+ ", with: "", options: .regularExpression)
    
    updateSpotlight()
  }
  
  static func createNote(name: String = Localized("New Note"), in directory: NodeModel) -> NodeModel {
    var node = NodeModel()
    Realm.transaction { (realm) in
      node = create(id: UUID().uuidString, parent: directory, isDirectory: false, realm: realm)
      node.isBodySaved = false
      node.name = Localized("New Note")
    }
    return node
  }
  
  private func updateNoteIndexIfNeeded(confirmUpdateNote: ConfirmUpdateNote) throws {
    let date = (try FileManager.default.attributesOfItem(atPath: url.path))[.modificationDate] as! Date
    let isNeedUpdate = date > lastUpdatedAt
    if !isNeedUpdate { return }
    
    let update = { [weak self] (isUpdate: Bool) in
      guard let s = self else { return }
      if isUpdate {
        s.setBody(try String(contentsOf: s.url))
        s.isBodySaved = true
        s.lastUpdatedAt = date
      } else {
        try s.save()
      }
    }
    if isBodySaved {
      try update(true)
    } else {
      try confirmUpdateNote(self, update)
    }
  }
  
  private func saveNote() throws {
    try BookmarkManager.shared.getBookmarkedURL(url, fallback: { url }) { (bookmarkedURL) in
      try body.write(to: bookmarkedURL, atomically: false, encoding: .utf8)
    }
    isBodySaved = true
  }
}

// ディレクトリ
extension NodeModel {
  var isTrash: Bool {
    return id == NodeModel.trashId
  }
  
  var isRoot: Bool {
    return parent?.parent == nil
  }
  
  static func root(for workspace: WorkspaceModel = .selectedValue, realm: Realm? = nil) -> NodeModel {
    if let root = workspace.nodes.filter("parent = nil").first {
      return root
    }
    let root = NodeModel()
    root.workspace = workspace
    root.isDirectory = true
    
    if let realm = realm {
      realm.add(root)
    } else {
      Realm.transaction { (realm) in
        realm.add(root)
      }
    }
    return root
  }
  
  static func roots(query: String?, for workspace: WorkspaceModel = WorkspaceModel.selectedValue) -> [NodeModel] {
    var parent = NodeModel()
    parent = root(for: workspace)
    return parent.sortedChildren(query: query)
  }
  
  var sortedDirectoryChildren: Results<NodeModel> {
    return children.filter("isDeleted = %@ and index >= %@ and isDirectory = %@", false, 0, true).sorted(byKeyPath: "index")
  }
  
  func setDirectoryName(_ name: String) throws {
    self.name = name
    try save()
  }
  
  @discardableResult
  static func createDirectory(name: String = Localized("New Directory"), parent: NodeModel?) throws -> NodeModel {
    var node = NodeModel()
    try Realm.transaction { (realm) in
      let parent = parent ?? root()
      node = create(id: UUID().uuidString, parent: parent, isDirectory: true, realm: realm)
      node.name = name
      try node.save()
    }
    return node
  }
  
  func getDirectoryInfo() throws -> DirectoryInfo {
    try BookmarkManager.shared.getBookmarkedURL(url, fallback: { url }) { (bookmarkedURL) in
      try FileManager.default.createDirectoryIfNeeded(url: bookmarkedURL)
    }
    return DirectoryInfo(directoryUrl: url)
  }
  
  func getDirectoryIsNeedUpdate(info: DirectoryInfo? = nil) throws -> Bool {
    let tmp: DirectoryInfo
    if let info = info {
      tmp = info
    } else {
      tmp = try getDirectoryInfo()
    }
    return tmp.lastUpdatedAt > lastUpdatedAt
  }
  
  private func updateDirectoryIndexIfNeeded(confirmUpdateNote: ConfirmUpdateNote, realm: Realm) throws {
    let info = try getDirectoryInfo()
    let isNeedUpdate = try getDirectoryIsNeedUpdate(info: info)
    if !isNeedUpdate { return }
    lastUpdatedAt = info.lastUpdatedAt
    name = info.name
    let childUrls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [], options: [])
    var newChildren = Set<String>()
    for childUrl in childUrls {
      if childUrl.pathExtension != "md" && !childUrl.hasDirectoryPath { continue }
      let id = childUrl.deletingPathExtension().lastPathComponent
      let isDirectory = childUrl.hasDirectoryPath
      let node = NodeModel.node(for: id, realm: realm) ?? .create(id: id, parent: self, isDirectory: isDirectory, realm: realm)
      let nodeInfo = info.children[id]
      node.index = nodeInfo?.index ?? -1
      node.isDeleted = nodeInfo?.isDeleted ?? false
      try node.updateIndexIfNeeded(confirmUpdateNote: confirmUpdateNote, realm: realm)
      newChildren.insert(node.id)
    }
    realm.delete(children.filter { !newChildren.contains($0.id) })
  }
  
  private func saveDirectory() throws {
    try BookmarkManager.shared.getBookmarkedURL(url, fallback: { url }) { (bookmarkedURL) in
      try FileManager.default.createDirectoryIfNeeded(url: bookmarkedURL)
      try DirectoryInfo(children: children, directory: self).write(to: bookmarkedURL)
    }
  }
}

// スポットライト
extension NodeModel {
  private func updateSpotlight() {
    if isDirectory { return }
    let attribute = CSSearchableItemAttributeSet(itemContentType: "org.annay.workspace")
    attribute.title = name
    attribute.contentDescription = body
    let item = CSSearchableItem(uniqueIdentifier: id, domainIdentifier: nil, attributeSet: attribute)
    CSSearchableIndex.default().indexSearchableItems([item], completionHandler: nil)
  }
}
