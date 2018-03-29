//
//  WorkspaceModel.swift
//  ModelExample
//
//  Created by Koji Murata on 2018/03/23.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation
import CoreSpotlight
import RealmSwift
import RxSwift
import RxRealm

final class WorkspaceModel: Object {
  private struct Key {
    static let SelectedIndex = "WorkspaceModel/SelectedIndex"
  }
  static var fileExtension: String { return "annay" }
  
  private let bag = DisposeBag()
  
  @objc dynamic private(set) var id = UUID().uuidString
  @objc dynamic private var directoryPath = ""
  @objc dynamic private var index = -1
  @objc dynamic var selectedNode: NodeModel?
  
  private lazy var nameSubject = BehaviorSubject<String>(value: nameValue)
  var nameObservable: Observable<String> { return nameSubject }
  var nameValue: String { return directoryUrl.deletingPathExtension().lastPathComponent }
  func setName(_ name: String) throws {
    if nameValue == name { return }
    try setDirectoryUrl(directoryUrl.deletingLastPathComponent().appendingPathComponent(name).appendingPathExtension(WorkspaceModel.fileExtension))
  }
  
  var savedObservable: Observable<Bool> {
    return Observable.collection(from: nodes.filter("isBodySaved = false")).map { $0.count == 0 }
  }
  
  static let spaces = Realm.instance.objects(WorkspaceModel.self).sorted(byKeyPath: "index")
  static let observableSpaces = Observable.collection(from: spaces)
  
  static private let selected = Variable(getSelected())
  static var selectedObservable: Observable<WorkspaceModel> { return selected.asObservable() }
  static var selectedValue: WorkspaceModel { return selected.value }
  static var selectedIndex: Int {
    get { return UserDefaults.standard.integer(forKey: Key.SelectedIndex) }
    set {
      let ud = UserDefaults.standard
      ud.set(newValue, forKey: Key.SelectedIndex)
      ud.synchronize()
      selected.value = getSelected()
    }
  }
  
  static func getSelected() -> WorkspaceModel {
    if let selected = spaces[safe: selectedIndex] ?? spaces.first { return selected }
    return try! createDefault()
  }
  
  func select() {
    if WorkspaceModel.selectedIndex != WorkspaceModel.spaces.index(of: self) {
      WorkspaceModel.selectedIndex = WorkspaceModel.spaces.index(of: self) ?? 0
    }
  }
  
  static func move(from fromIndex: Int, to toIndex: Int) {
    Realm.transaction { (realm) in
      let workspaces = realm.objects(WorkspaceModel.self).sorted(byKeyPath: "index")
      let moveWorkspace = workspaces[fromIndex]
      moveWorkspace.index = -1
      for (index, workspace) in workspaces.enumerated() {
        if index < toIndex {
          workspace.index = index
        } else {
          workspace.index = index + 1
        }
      }
      moveWorkspace.index = toIndex
    }
  }
  
  @discardableResult
  private static func createDefault() throws -> WorkspaceModel {
    return try create(name: Localized("Default Workspace"), parentDirectory: FileManager.default.applicationSupport)
  }
  
  static func createDefaultIfNeeded() throws {
    if spaces.count == 0 { try createDefault() }
  }
  
  private lazy var directoryUrlSubject = BehaviorSubject<URL>(value: directoryUrl)
  var directoryUrlObservable: Observable<URL> { return directoryUrlSubject }
  
  func setDirectoryUrl(_ url: URL) throws {
    if directoryUrl == url { return }
    if FileManager.default.fileExists(atPath: url.path) { throw MarkDownEditorError.fileExists(oldUrl: url) }
    if FileManager.default.fileExists(atPath: directoryUrl.path) { try FileManager.default.moveItem(at: directoryUrl, to: url) }
    directoryUrl = url
  }
  
  var updatedAtObservable: Observable<Date> {
    return Observable.collection(from: nodes.sorted(byKeyPath: "lastUpdatedAt", ascending: false)).map { $0.first?.lastUpdatedAt ?? Date() }
  }
  
  let detectChange = PublishSubject<Void>()
  
  private(set) var directoryUrl: URL {
    get { return URL(fileURLWithPath: directoryPath) }
    set {
      directoryPath = newValue.path
      nameSubject.onNext(nameValue)
      directoryUrlSubject.onNext(newValue)
    }
  }
  
  let nodes = LinkingObjects(fromType: NodeModel.self, property: "workspace")
  
  @discardableResult
  static func create(name: String, parentDirectory: URL, confirmUpdateNote: NodeModel.ConfirmUpdateNote = { _, _ in }) throws -> WorkspaceModel {
    return try create(
      directoryUrl: parentDirectory.appendingPathComponent(name).appendingPathExtension(WorkspaceModel.fileExtension),
      confirmUpdateNote: confirmUpdateNote
    )
  }
  
  @discardableResult
  static func create(directoryUrl: URL, confirmUpdateNote: NodeModel.ConfirmUpdateNote = { _, _ in }) throws -> WorkspaceModel {
    let workspace = WorkspaceModel()
    workspace.directoryUrl = directoryUrl
    workspace.index = (spaces.last?.index ?? -1) + 1
    try Realm.transaction { (realm) in
      try workspace.updateIndex(confirmUpdateNote: confirmUpdateNote, realm: realm)
    }
    return workspace
  }
  
  func updateIndex(confirmUpdateNote: NodeModel.ConfirmUpdateNote, realm: Realm) throws {
    try NodeModel.root(for: self, realm: realm).updateIndexIfNeeded(confirmUpdateNote: confirmUpdateNote, realm: realm)
    detectChange.onNext(())
  }
  
  var notesUrl: URL {
    return directoryUrl.appendingPathComponent("notes", isDirectory: true)
  }
  
  func deleteFromSearchableIndex() {
    let nodeIds = [String](Realm.instance.objects(NodeModel.self).filter("workspace = %@ and isDirectory = false", self).map { $0.id })
    CSSearchableIndex.default().deleteSearchableItemsWithDataStore(with: nodeIds)
  }
  
  override class func primaryKey() -> String? { return "directoryPath" }
  override class func ignoredProperties() -> [String] { return ["nameSubject", "directoryUrlSubject"] }
}
