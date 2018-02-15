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
import Zip

final class WorkspaceModel {
  static var fileExtension: String { return "mdworkspace" }
  
  private let bag = DisposeBag()
  
  let id: String
  private var workspaceDirectoryName: String
  private let _url: Variable<URL>
  private let _name: Variable<String>
  private let _updatedAt: Variable<Date>
  private let updatedAtFormatter = DateFormatter(dateStyle: .short, timeStyle: .short)
  private let updateId: Variable<String>
  private let lastSavedUpdateId: Variable<String>
  private let _detectChange = PublishSubject<Void>()

  private static var updatedAtKey: String { return "updatedAt" }
  fileprivate static var updateIdKey: String { return "updatedId" }
  private var info: [String: Any] {
    didSet {
      do {
        let data = try JSONSerialization.data(withJSONObject: info, options: [])
        try data.write(to: workspaceDirectory.infoFile)
      } catch {}
    }
  }
  
  var urlObservable: Observable<URL> { return _url.asObservable() }
  var url: URL { return _url.value }
  var nameObservable: Observable<String> { return _name.asObservable() }
  var name: String { return _name.value }
  var updatedAtObservable: Observable<Date> { return _updatedAt.asObservable() }
  var savedObservable: Observable<Bool> {
    return Observable.combineLatest(updateId.asObservable(), lastSavedUpdateId.asObservable(), resultSelector: { $0 == $1 })
  }
  var detectChange: Observable<Void> { return _detectChange }
  
  private var isSaved: Bool { return updateId.value == lastSavedUpdateId.value }
  
  private static func workspaceDirectory(for name: String) -> URL {
    return FileManager.default.applicationWorkspace.appendingPathComponent(name, isDirectory: true)
  }
  
  static func conflictMessage(for name: String) -> String {
    return String(format: Localized("File update for '%@' was detected.\nWhich one should take priority?"), name)
  }
  
  var workspaceDirectory: URL {
    return WorkspaceModel.workspaceDirectory(for: workspaceDirectoryName)
  }
  
  func setUrl(_ newUrl: URL) throws {
    if url == newUrl { return }
    if FileManager.default.fileExists(atPath: newUrl.path) { throw MarkDownEditorError.fileExists(oldUrl: url) }
    if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.moveItem(at: url, to: newUrl) }
    _url.value = newUrl
    saveToUserDefaults()
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
        try WorkspaceModel(url: url).saveToUserDefaults()
      } catch {
        NSAlert(error: error).runModal()
        return false
      }
    }
    return true
  }

  private init(id: String, url: URL, lastSavedUpdateId: String?, workspaceDirectoryName: String) throws {
    self.id = id
    _url = Variable(url)
    _name = Variable(url.name)
    self.workspaceDirectoryName = workspaceDirectoryName
    
    let tmpLastSavedUpdateId = try WorkspaceModel.changeDetected(
      at: url,
      workspaceDirectoryName: &self.workspaceDirectoryName,
      lastSavedUpdateId: lastSavedUpdateId
    )
    
    let workspaceDirectory = WorkspaceModel.workspaceDirectory(for: workspaceDirectoryName)
    info = try workspaceDirectory.getInfoData()
    
    _updatedAt = Variable<Date>(Date())
    updateId = Variable("")
    self.lastSavedUpdateId = Variable("")
    
    reloadInfo(lastSavedUpdateId: tmpLastSavedUpdateId ?? lastSavedUpdateId)

    selectedNodeId = UserDefaults.standard.string(forKey: Key.SelectedNodeId(for: self))
    try FileManager.default.createDirectoryIfNeeded(url: workspaceDirectory.resourceDirectory)
  }
  
  convenience init(name: String, parentDirectoryUrl: URL) throws {
    let url = parentDirectoryUrl.appendingPathComponent(name).appendingPathExtension(WorkspaceModel.fileExtension)
    if FileManager.default.fileExists(atPath: url.path) {
      throw MarkDownEditorError.fileExists(oldUrl: nil)
    }
    try self.init(id: UUID().uuidString, url: url, lastSavedUpdateId: nil, workspaceDirectoryName: UUID().uuidString)
    _name.value = name
  }
  
  convenience init(url: URL) throws {
    try self.init(id: UUID().uuidString, url: url, lastSavedUpdateId: nil, workspaceDirectoryName: UUID().uuidString)
  }
  
  private func reloadInfo(lastSavedUpdateId: String?) {
    _updatedAt.value = updatedAtFormatter.date(from: info[WorkspaceModel.updatedAtKey] as? String ?? "") ?? Date()
    let updateId = info[WorkspaceModel.updateIdKey] as? String ?? ""
    self.updateId.value = updateId
    self.lastSavedUpdateId.value = lastSavedUpdateId ?? updateId
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
  
  private var detectedChangeForSave = true
  
  func changeDetected() {
    if !detectedChangeForSave {
      detectedChangeForSave = true
      return
    }
    do {
      if let lastSavedUpdateId = try WorkspaceModel.changeDetected(
        at: url,
        workspaceDirectoryName: &workspaceDirectoryName,
        lastSavedUpdateId: lastSavedUpdateId.value
      ) {
        self.lastSavedUpdateId.value = lastSavedUpdateId
        info = try workspaceDirectory.getInfoData()
        saveToUserDefaults()
        reloadInfo(lastSavedUpdateId: nil)
        _detectChange.onNext(())
      }
    } catch {
      NSAlert(error: error).runModal()
    }
  }
  
  @discardableResult
  static func changeDetected(at url: URL, workspaceDirectoryName: inout String, lastSavedUpdateId: String?) throws -> String? {
    var workspaceDirectory = WorkspaceModel.workspaceDirectory(for: workspaceDirectoryName)
    
    var tmpLastSavedUpdateId: String? = nil

    let fileManager = FileManager.default
    if fileManager.fileExists(atPath: url.path) {
      Zip.addCustomFileExtension(WorkspaceModel.fileExtension)
      
      if fileManager.fileExists(atPath: workspaceDirectory.path) {
        let tmpDirectory = fileManager.applicationTmp.appendingPathComponent(workspaceDirectoryName)
        try Zip.unzipFile(url, destination: tmpDirectory, overwrite: true, password: nil)
        let oldLastSavedUpdatedId = lastSavedUpdateId ?? workspaceDirectory.updateId ?? ""
        if tmpDirectory.updateId != oldLastSavedUpdatedId {
          
          let moveTmpToNewWorkspace = { (workspaceDirectoryName: inout String) in
            try fileManager.removeItem(at: workspaceDirectory)
            workspaceDirectoryName = UUID().uuidString
            workspaceDirectory = WorkspaceModel.workspaceDirectory(for: workspaceDirectoryName)
            try fileManager.moveItem(at: tmpDirectory, to: workspaceDirectory)
            tmpLastSavedUpdateId = workspaceDirectory.updateId
            try ResourceManager.copy(from: workspaceDirectory.resourceDirectory)
          }
          
          if workspaceDirectory.updateId == oldLastSavedUpdatedId {
            try moveTmpToNewWorkspace(&workspaceDirectoryName)
          } else {
            let alert = NSAlert()
            alert.messageText = WorkspaceModel.conflictMessage(for: url.name)
            alert.addButton(withTitle: Localized("File"))
            alert.addButton(withTitle: Localized("Editing Data"))
            if alert.runModal() == .alertFirstButtonReturn {
              try moveTmpToNewWorkspace(&workspaceDirectoryName)
            }
          }
        }
      } else {
        try Zip.unzipFile(url, destination: workspaceDirectory, overwrite: true, password: nil)
        try ResourceManager.copy(from: workspaceDirectory.resourceDirectory)
      }
    } else {
      try fileManager.createDirectoryIfNeeded(url: workspaceDirectory)
    }
    return tmpLastSavedUpdateId
  }
  
  func save() {
    detectedChangeForSave = false
    do {
      let urls = [
        workspaceDirectory.realmFile,
        workspaceDirectory.secretKeyFile,
        workspaceDirectory.infoFile,
        workspaceDirectory.resourceDirectory,
      ]
      try FileManager.default.createDirectoryIfNeeded(url: url.deletingLastPathComponent())
      try Zip.zipFiles(paths: urls, zipFilePath: url, password: nil, compression: .BestSpeed, progress: nil)
    } catch {
      NSAlert(error: error).runModal()
    }
    lastSavedUpdateId.value = updateId.value
    saveToUserDefaults()
  }
  
  func reset() {
    if isSaved { return }
    let alert = NSAlert()
    alert.messageText = Localized("Reset Workspace")
    alert.informativeText = Localized("Data being edited will be lost")
    alert.addButton(withTitle: Localized("Reset"))
    alert.addButton(withTitle: Localized("Cancel"))
    if alert.runModal() == .alertFirstButtonReturn {
      do {
        try FileManager.default.removeItem(at: workspaceDirectory)

        workspaceDirectoryName = UUID().uuidString
        try Zip.unzipFile(url, destination: workspaceDirectory, overwrite: true, password: nil)
        try ResourceManager.copy(from: workspaceDirectory.resourceDirectory)

        info = try workspaceDirectory.getInfoData()
        saveToUserDefaults()
        reloadInfo(lastSavedUpdateId: nil)
        _detectChange.onNext(())
      } catch {
        NSAlert(error: error).runModal()
      }
    }
  }
  
  func update() {
    _updatedAt.value = Date()
    updateId.value = UUID().uuidString
    info = [
      WorkspaceModel.updateIdKey: updateId.value,
      WorkspaceModel.updatedAtKey: updatedAtFormatter.string(from: _updatedAt.value),
    ]
    saveToUserDefaults()
  }
  
  func saveToUserDefaults() {
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
    return try WorkspaceModel(name: Localized("Default Workspace"), parentDirectoryUrl: FileManager.default.applicationSupport)
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
      "lastSavedUpdateId": lastSavedUpdateId.value,
      "workspaceDirectoryName": workspaceDirectoryName,
    ]
  }
  
  convenience init?(dictionary: [String : Any]) {
    guard
      let id = dictionary["id"] as? String,
      let urlString = dictionary["url"] as? String,
      let url = URL(string: urlString),
      let lastSavedUpdateId = dictionary["lastSavedUpdateId"] as? String,
      let workspaceDirectoryName = dictionary["workspaceDirectoryName"] as? String
      else { return nil }
    do {
      try self.init(id: id, url: url, lastSavedUpdateId: lastSavedUpdateId, workspaceDirectoryName: workspaceDirectoryName)
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
  fileprivate var infoFile: URL {
    return appendingPathComponent("info.json")
  }
  
  fileprivate var updateId: String? {
    guard let info = try? getInfoData() else { return nil }
    return info[WorkspaceModel.updateIdKey] as? String
  }
  
  fileprivate func getInfoData() throws -> [String: Any] {
    let url = infoFile
    if FileManager.default.fileExists(atPath: url.path) {
      let infoData = try Data(contentsOf: url)
      return try JSONSerialization.jsonObject(with: infoData, options: []) as? [String: Any] ?? [:]
    } else {
      return [:]
    }
  }
}

extension FileManager {
  fileprivate var applicationWorkspace: URL {
    return applicationSupport.appendingPathComponent("workspace", isDirectory: true)
  }

  fileprivate var applicationTmp: URL {
    return applicationSupport.appendingPathComponent("tmp", isDirectory: true)
  }
}
