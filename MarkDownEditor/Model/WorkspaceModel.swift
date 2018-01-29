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
  private static var fileExtension: String { return "mdworkspace" }
  
  private let bag = DisposeBag()
  
  let id: String
  let url: Variable<URL>
  let name: Variable<String>

  private init(id: String, url: URL) throws {
    self.id = id
    self.url = Variable(url)
    
    if !FileManager.default.fileExists(atPath: url.path) {
      try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }

    name = Variable(url.deletingPathExtension().lastPathComponent)

    name.asObservable().pairwised.subscribe(onNext: { [weak self] (oldName, newName) in
      if oldName == newName { return }
      guard let s = self else { return }
      let newUrl = s.url.value
        .deletingPathExtension()
        .deletingLastPathComponent()
        .appendingPathComponent(newName)
        .appendingPathExtension(WorkspaceModel.fileExtension)
      try! FileManager.default.moveItem(at: s.url.value, to: newUrl)
      s.url.value = newUrl
    }).disposed(by: bag)
    
    self.url.asObservable().pairwised.subscribe(onNext: { [weak self] (oldUrl, newUrl) in
      if oldUrl == newUrl { return }
      self?.save()
    }).disposed(by: bag)
  }
  
  convenience init(name: String, parentDirectoryUrl: URL) throws {
    let url = parentDirectoryUrl.appendingPathComponent(name).appendingPathExtension(WorkspaceModel.fileExtension)
    if FileManager.default.fileExists(atPath: url.path) {
      throw MarkDownEditorError.fileExists
    }
    try self.init(id: UUID().uuidString, url: url)
    self.name.value = name
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
    get {
      let index = UserDefaults.standard.integer(forKey: Key.SelectedIndex)
      if spaces.value.count <= index { return 0 }
      return index
    }
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
