//
//  WorkspaceModel.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/17.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation

struct WorkspaceModel {
  let id: String
  let name: String
  let url: URL

  private init(id: String, name: String, url: URL) {
    self.id = id
    self.name = name
    self.url = url
  }
  
  init(name: String, url: URL) {
    self.init(id: UUID().uuidString, name: name, url: url)
  }
  
  private struct Key {
    static let Spaces = "WorkspaceModel/Spaces"
  }
  
  private(set) static var spaces: [WorkspaceModel] {
    get { return UserDefaults.standard.savableObjectArray(forKey: Key.Spaces) ?? [] }
    set {
      let ud = UserDefaults.standard
      ud.set(newValue, forKey: Key.Spaces)
      ud.synchronize()
    }
  }
  
//  func save() {
//    WorkspaceModel.spaces.append(self)
//  }
//
//  static func delete(_ space: WorkspaceModel) {
//    spaces.remove(object: space)
//  }
//
//  static func move(_ movingSpaces: [WorkspaceModel], to index: Int) {
//    var tmpSpaces = spaces
//    let indexes = tmpSpaces.remove(objects: movingSpaces)
//    let fixedIndex = index - indexes.filter { $0 < index }.count
//    tmpSpaces.insert(<#T##newElement: WorkspaceModel##WorkspaceModel#>, at: <#T##Int#>)
//  }
  // ArrayControllerを使いたい
}

extension WorkspaceModel: SavableInUserDefaults {
  var dictionary: [String : Any] {
    return [
      "id": id,
      "name": name,
      "url": url.absoluteString,
    ]
  }
  
  init?(dictionary: [String : Any]) {
    guard
      let id = dictionary["id"] as? String,
      let name = dictionary["name"] as? String,
      let urlString = dictionary["url"] as? String,
      let url = URL(string: urlString)
      else { return nil }
    self.init(id: id, name: name, url: url)
  }
}

extension WorkspaceModel: Equatable {
  static func ==(lhs: WorkspaceModel, rhs: WorkspaceModel) -> Bool {
    return lhs.id == rhs.id
  }
}
