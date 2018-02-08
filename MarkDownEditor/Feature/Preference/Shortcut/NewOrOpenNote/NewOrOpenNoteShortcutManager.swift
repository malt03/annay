//
//  NewOrOpenNoteShortcutManager.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/08.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import RxSwift
import Foundation
import MASShortcut

final class NewOrOpenNoteShortcutManager {
  enum Kind: String {
    case new
    case open
    
    static var all: [Kind] { return [.new, .open] }
  }
  
  static let shared = NewOrOpenNoteShortcutManager()
  
  private let bag = DisposeBag()
  
  struct Key {
    static func WorkspaceId(for kind: Kind) -> String { return "NewOrOpenNoteShortcutManager/WorkspaceId/\(kind.rawValue)" }
    static func NodeId(for kind: Kind) -> String { return "NewOrOpenNoteShortcutManager/NodeId/\(kind.rawValue)" }
    static func ShortcutKey(for kind: Kind) -> String { return "NewOrOpenNoteShortcutPreferenceViewController/Shortcut/\(kind.rawValue)" }
  }
  
  private init() {
    let ud = UserDefaults.standard
    
    var workspaces = Kind.all.reduce([Kind: WorkspaceModel]()) { (oldValue, kind) in
      guard let workspaceId = ud.string(forKey: Key.WorkspaceId(for: kind)) else { return oldValue }
      var new = oldValue
      new[kind] = WorkspaceModel.spaces.value.first(where: { $0.id == workspaceId })
      return new
    }
    self.workspaces = workspaces

    nodes = Kind.all.reduce([Kind: NodeModel]()) { (oldValue, kind) in
      guard
        let nodeId = ud.string(forKey: Key.NodeId(for: kind)),
        let workspace = workspaces[kind]
        else { return oldValue }
      var new = oldValue
      new[kind] = NodeModel.node(for: nodeId, for: workspace)
      return new
    }
  }
  
  func prepare() {
    MASShortcutBinder.shared().bindShortcut(withDefaultsKey: Key.ShortcutKey(for: .new)) { [weak self] in
      guard let s = self else { return }
      guard let node = s.node(for: .new), let workspace = s.workspace(for: .new) else {
        NSAlert(localizedMessageText: "No parent directory was selected.").runModal()
        return
      }
      workspace.select()
      let note = NodeModel.createNote(in: node)
      note.selected()
      NotificationCenter.default.post(name: .MoveFocusToEditor, object: nil)
      Application.shared.activate(ignoringOtherApps: true)
      for handler in s.insertNodeHandlers {
        handler(note)
      }
    }
  }
  
  func addInsertNodeHandler(_ handler: @escaping InsertNodeHandler) {
    insertNodeHandlers.append(handler)
  }
  
  typealias InsertNodeHandler = (_ node: NodeModel) -> Void
  
  private var insertNodeHandlers = [InsertNodeHandler]()
  
  func workspace(for kind: Kind) -> WorkspaceModel? { return workspaces[kind] }
  func node(for kind: Kind) -> NodeModel? { return nodes[kind] }
  
  func setWorkspace(_ workspace: WorkspaceModel, for kind: Kind) {
    workspaces[kind] = workspace
  }

  func setNode(_ node: NodeModel?, for kind: Kind) {
    nodes[kind] = node
  }

  private var workspaces: [Kind: WorkspaceModel] {
    didSet {
      let ud = UserDefaults.standard
      for (kind, workspace) in workspaces {
        ud.set(workspace.id, forKey: Key.WorkspaceId(for: kind))
      }
      ud.synchronize()
    }
  }
  private var nodes: [Kind: NodeModel] {
    didSet {
      let ud = UserDefaults.standard
      for (kind, node) in nodes {
        ud.set(node.id, forKey: Key.NodeId(for: kind))
      }
      ud.synchronize()
    }
  }
}
