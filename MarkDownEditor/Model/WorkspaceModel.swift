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
  let name = Variable<String>("")

  private init(id: String, url: URL) {
    self.id = id
    self.url = Variable(url)
    name.value = (settings["name"] as? String) ?? ""
    
    name.asObservable().subscribe(onNext: { [weak self] (name) in
       self?.settings["name"] = name
    }).disposed(by: bag)
    
    try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
  }
  
  convenience init(url: URL) {
    self.init(id: UUID().uuidString, url: url)
  }
  
  private var _settings: [String: Any]?
  
  private var settings: [String: Any] {
    get {
      if let _settings = _settings { return _settings }
      guard
        let data = try? Data(contentsOf: settingFileUrl),
        let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any]
        else { return [:] }
      _settings = json
      return json
    }
    set {
      do {
        let data = try JSONSerialization.data(withJSONObject: newValue, options: [])
        try data.write(to: settingFileUrl)
        _settings = newValue
      } catch {}
    }
  }
  
  private var settingFileUrl: URL {
    return url.value.appendingPathComponent("settings.json")
  }
  
  private struct Key {
    static let Spaces = "WorkspaceModel/Spaces"
    static let SelectedIndex = "WorkspaceModel/SelectedIndex"
  }
  
  private(set) static var spaces: [WorkspaceModel] {
    get {
      let spaces: [WorkspaceModel] = UserDefaults.standard.savableObjectArray(forKey: Key.Spaces) ?? []
      if spaces.count == 0 {
        return [createDefault()]
      }
      return spaces
    }
    set {
      let ud = UserDefaults.standard
      ud.set(newValue, forKey: Key.Spaces)
      ud.synchronize()
    }
  }
  
  private static var selectedIndex: Int {
    get { return UserDefaults.standard.integer(forKey: Key.SelectedIndex) }
    set {
      let ud = UserDefaults.standard
      ud.set(newValue, forKey: Key.SelectedIndex)
      ud.synchronize()
      selected.onNext(spaces[newValue])
    }
  }
  
  static let selected = BehaviorSubject<WorkspaceModel>(value: spaces[selectedIndex])
  
  func select() {
    WorkspaceModel.selectedIndex = WorkspaceModel.spaces.index(of: self) ?? 0
  }
  
  func save() {
    WorkspaceModel.spaces.append(self)
  }

  static func delete(_ space: WorkspaceModel) {
    spaces.remove(object: space)
  }

  static func move(_ movingSpaces: [WorkspaceModel], to index: Int) {
    var tmpSpaces = spaces
    let indexes = tmpSpaces.remove(objects: movingSpaces)
    let fixedIndex = index - indexes.filter { $0 < index }.count
    tmpSpaces.insert(contentsOf: movingSpaces, at: fixedIndex)
    spaces = tmpSpaces
  }
  
  private static func createDefault() -> WorkspaceModel {
    let supportDirectory = FileManager().urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let workspaceUrl = supportDirectory
      .appendingPathComponent(Bundle.main.bundleIdentifier ?? "", isDirectory: true)
      .appendingPathComponent("workspace", isDirectory: true)
    let workspace = WorkspaceModel(url: workspaceUrl)
    workspace.name.value = Localized("Default Workspace")
    spaces = [workspace]
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
    self.init(id: id, url: url)
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
