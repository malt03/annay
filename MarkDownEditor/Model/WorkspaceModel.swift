//
//  WorkspaceModel.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/17.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import RxSwift
import Cocoa

struct WorkspaceModel {
  let id: String
  var name: Variable<String>
  var url: Variable<URL>
  var imageUrl: Variable<URL?>

  private init(id: String, name: String, url: URL, imageUrl: URL?) {
    self.id = id
    self.name = Variable(name)
    self.url = Variable(url)
    self.imageUrl = Variable(imageUrl)
  }
  
  init(name: String, url: URL, imageUrl: URL?) {
    self.init(id: UUID().uuidString, name: name, url: url, imageUrl: imageUrl)
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
    }
  }
  
  static var selected: WorkspaceModel {
    return spaces[selectedIndex]
  }
  
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
    let workspace = WorkspaceModel(name: Localized("Default"), url: workspaceUrl, imageUrl: nil)
    spaces = [workspace]
    return workspace
  }
}

extension WorkspaceModel: SavableInUserDefaults {
  var dictionary: [String : Any] {
    var dict = [
      "id": id,
      "name": name.value,
      "url": url.value.absoluteString,
    ]
    if let imageUrl = imageUrl.value {
      dict["imageUrl"] = imageUrl.absoluteString
    }
    return dict
  }
  
  init?(dictionary: [String : Any]) {
    guard
      let id = dictionary["id"] as? String,
      let name = dictionary["name"] as? String,
      let urlString = dictionary["url"] as? String,
      let url = URL(string: urlString)
      else { return nil }
    let imageUrl = URL(string: dictionary["imageUrl"] as? String ?? "")
    self.init(id: id, name: name, url: url, imageUrl: imageUrl)
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
