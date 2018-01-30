//
//  WorkspaceModel.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/17.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import RxSwift
import RealmSwift
import Cocoa

final class WorkspaceModel {
  static var fileExtension: String { return "mdworkspace" }
  
  private let bag = DisposeBag()
  
  let id: String
  private let _url: Variable<URL>
  private let _name: Variable<String>
  
  var urlObservable: Observable<URL> { return _url.asObservable() }
  var url: URL { return _url.value }
  var nameObservable: Observable<String> { return _name.asObservable() }
  var name: String { return _name.value }
  
  func setUrl(_ newUrl: URL) throws {
    if url == newUrl { return }
    if FileManager.default.fileExists(atPath: newUrl.path) { throw MarkDownEditorError.fileExists(oldUrl: url) }
    try FileManager.default.moveItem(at: url, to: newUrl)
    _url.value = newUrl
    save()
  }
  
  func setName(_ newName: String) throws {
    if name == newName { return }
    let newUrl = url
      .deletingPathExtension()
      .deletingLastPathComponent()
      .appendingPathComponent(newName)
      .appendingPathExtension(WorkspaceModel.fileExtension)
    try setUrl(newUrl)
    _name.value = newName
  }
  
  static func open(url: URL) -> Bool {
    if let index = WorkspaceModel.spaces.value.map({ $0.url.appendingPathComponent("x") }).index(of: url.appendingPathComponent("x")) {
      WorkspaceModel.spaces.value[index].select()
    } else {
      do {
        try WorkspaceModel(url: url).save()
      } catch {
        NSAlert(error: error).runModal()
        return false
      }
    }
    return true
  }

  private init(id: String, url: URL) throws {
    self.id = id
    _url = Variable(url)
    
    if !FileManager.default.fileExists(atPath: url.path) {
      try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }

    _name = Variable(url.name)
    
    selectedNodeId = UserDefaults.standard.string(forKey: Key.SelectedNodeId(for: self))
  }
  
  convenience init(name: String, parentDirectoryUrl: URL) throws {
    let url = parentDirectoryUrl.appendingPathComponent(name).appendingPathExtension(WorkspaceModel.fileExtension)
    if FileManager.default.fileExists(atPath: url.path) {
      throw MarkDownEditorError.fileExists(oldUrl: nil)
    }
    try self.init(id: UUID().uuidString, url: url)
    _name.value = name
  }
  
  convenience init(url: URL) throws {
    try self.init(id: UUID().uuidString, url: url)
  }
  
  private struct Key {
    static let Spaces = "WorkspaceModel/Spaces"
    static let SelectedIndex = "WorkspaceModel/SelectedIndex"
    static func SelectedNodeId(for workspace: WorkspaceModel) -> String {
      return "WorkspaceModel/\(workspace.id)/SelectedNodeId"
    }
  }
  
  static var spaces: Variable<[WorkspaceModel]> = {
    var spaces: [WorkspaceModel] = UserDefaults.standard.savableObjectArray(forKey: Key.Spaces) ?? []
    let variable = Variable(spaces)
    _ = variable.asObservable().subscribe(onNext: { (workspaces) in
      let ud = UserDefaults.standard
      ud.set(workspaces, forKey: Key.Spaces)
      ud.synchronize()
    })
    
    if spaces.count == 0 {
      do {
        variable.value = [try createDefault()]
      } catch {
        NSAlert(error: error).runModal()
      }
    }
    return variable
  }()
  
  static var selectedIndex: Int {
    get {
      let index = UserDefaults.standard.integer(forKey: Key.SelectedIndex)
      if spaces.value.count <= index { return 0 }
      return index
    }
    set {
      let ud = UserDefaults.standard
      ud.set(newValue, forKey: Key.SelectedIndex)
      ud.synchronize()
      selected.value = spaces.value[newValue]
    }
  }
  
  static let selected = Variable<WorkspaceModel>(spaces.value[safe: selectedIndex] ?? spaces.value[0])
  
  func select() {
    WorkspaceModel.selectedIndex = WorkspaceModel.spaces.value.index(of: self) ?? 0
    NodeModel.createFirstDirectoryIfNeeded()
  }
  
  func save() {
    if let index = WorkspaceModel.spaces.value.index(of: self) {
      WorkspaceModel.spaces.value[index] = self
    } else {
      WorkspaceModel.spaces.value.append(self)
    }
  }

  static func move(from fromIndex: Int, to toIndex: Int) {
    var tmpSpaces = spaces.value
    let space = tmpSpaces[fromIndex]
    tmpSpaces.remove(at: fromIndex)
    var fixedToIndex = toIndex
    if fromIndex < toIndex {
      fixedToIndex -= 1
    }
    tmpSpaces.insert(space, at: fixedToIndex)
    spaces.value = tmpSpaces
    space.select()
  }
  
  private static func createDefault() throws -> WorkspaceModel {
    let supportDirectory = FileManager().urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let workspaceUrl = supportDirectory.appendingPathComponent(Bundle.main.bundleIdentifier ?? "", isDirectory: true)
    return try WorkspaceModel(name: Localized("Default Workspace"), parentDirectoryUrl: workspaceUrl)
  }
  
  var selectedNodeId: String? {
    didSet {
      let ud = UserDefaults.standard
      ud.set(selectedNodeId, forKey: Key.SelectedNodeId(for: self))
      ud.synchronize()
    }
  }
}

extension WorkspaceModel: SavableInUserDefaults {
  var dictionary: [String : Any] {
    return [
      "id": id,
      "url": url.absoluteString,
    ]
  }
  
  convenience init?(dictionary: [String : Any]) {
    guard
      let id = dictionary["id"] as? String,
      let urlString = dictionary["url"] as? String,
      let url = URL(string: urlString)
      else { return nil }
    do {
      try self.init(id: id, url: url)
    } catch {
      NSAlert(error: error).runModal()
      return nil
    }
  }
}

extension WorkspaceModel: Equatable {
  static func ==(lhs: WorkspaceModel, rhs: WorkspaceModel) -> Bool {
    return lhs.id == rhs.id
  }
}

extension WorkspaceModel: Hashable {
  var hashValue: Int { return id.hashValue }
}
