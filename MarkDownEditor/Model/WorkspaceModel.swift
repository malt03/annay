//
//  WorkspaceModel.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/17.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import RxSwift
import Cocoa

final class WorkspaceModel {
  private let bag = DisposeBag()
  
  let id: String
  let url: Variable<URL>
  let name: Variable<String>

  private var settings: [String: Any] {
    didSet {
      do {
        let data = try JSONSerialization.data(withJSONObject: settings, options: [])
        try data.write(to: url.value.settings)
      } catch {}
    }
  }

  private init(id: String, url: URL) throws {
    self.id = id
    self.url = Variable(url)
    
    if !FileManager.default.fileExists(atPath: url.settings.path) {
      try "{}".write(to: url.settings, atomically: true, encoding: .utf8)
    }

    let data = try Data(contentsOf: url.settings)
    settings = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]

    var name = settings["name"] as? String ?? ""
    if name == "" { name = url.deletingLastPathComponent().lastPathComponent }
    self.name = Variable(name)

    self.name.asObservable().subscribe(onNext: { [weak self] (name) in
      self?.settings["name"] = name
    }).disposed(by: bag)
    
    if !FileManager.default.fileExists(atPath: url.path) {
      try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }
  }
  
  convenience init(url: URL) throws {
    try self.init(id: UUID().uuidString, url: url)
  }
  
  private struct Key {
    static let Spaces = "WorkspaceModel/Spaces"
    static let SelectedIndex = "WorkspaceModel/SelectedIndex"
  }
  
  private(set) static var spaces: Variable<[WorkspaceModel]> = {
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
    get { return UserDefaults.standard.integer(forKey: Key.SelectedIndex) }
    set {
      let ud = UserDefaults.standard
      ud.set(newValue, forKey: Key.SelectedIndex)
      ud.synchronize()
      selected.onNext(spaces.value[newValue])
    }
  }
  
  static let selected = BehaviorSubject<WorkspaceModel>(value: spaces.value[safe: selectedIndex] ?? spaces.value[0])
  
  func select() {
    WorkspaceModel.selectedIndex = WorkspaceModel.spaces.value.index(of: self) ?? 0
    NodeModel.createFirstDirectoryIfNeeded()
  }
  
  func save() {
    WorkspaceModel.spaces.value.append(self)
  }

  static func delete(_ space: WorkspaceModel) {
    spaces.value.remove(object: space)
  }

  static func move(_ movingSpaces: [WorkspaceModel], to index: Int) {
    var tmpSpaces = spaces.value
    let indexes = tmpSpaces.remove(objects: movingSpaces)
    let fixedIndex = index - indexes.filter { $0 < index }.count
    tmpSpaces.insert(contentsOf: movingSpaces, at: fixedIndex)
    spaces.value = tmpSpaces
  }
  
  private static func createDefault() throws -> WorkspaceModel {
    let supportDirectory = FileManager().urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let workspaceUrl = supportDirectory
      .appendingPathComponent(Bundle.main.bundleIdentifier ?? "", isDirectory: true)
      .appendingPathComponent("workspace", isDirectory: true)
    let workspace = try WorkspaceModel(url: workspaceUrl)
    workspace.name.value = Localized("Default Workspace")
    return workspace
  }
}

extension WorkspaceModel: SavableInUserDefaults {
  var dictionary: [String : Any] {
    return [
      "id": id,
      "url": url.value.absoluteString,
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

extension URL {
  fileprivate var settings: URL {
    return appendingPathComponent("settings.json")
  }
}
