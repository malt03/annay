//
//  NewWorkspaceShortcutManager.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/08.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import RxSwift
import Foundation
import MASShortcut

final class NewWorkspaceShortcutManager {
  static let shared = NewWorkspaceShortcutManager()
  
  private let bag = DisposeBag()
  
  struct Key {
    static let WorkspaceId = "NewWorkspaceShortcutManager/WorkspaceId"
    static let NodeId = "NewWorkspaceShortcutManager/NodeId"
    static let ShortcutKey = "NewWorkspaceShortcutPreferenceViewController/Shortcut"
  }
  
  private init() {
    let ud = UserDefaults.standard
    let workspace: WorkspaceModel
    if let workspaceId = ud.string(forKey: Key.WorkspaceId) {
      workspace = WorkspaceModel.spaces.value.first(where: { $0.id == workspaceId }) ?? WorkspaceModel.selected.value
    } else {
      workspace = WorkspaceModel.selected.value
    }
    self.workspace = Variable(workspace)
    
    if let nodeId = ud.string(forKey: Key.NodeId) {
      node = NodeModel.node(for: nodeId, for: workspace)
    }
    
    self.workspace.asObservable().subscribe(onNext: { (workspace) in
      let ud = UserDefaults.standard
      ud.set(workspace.id, forKey: Key.WorkspaceId)
      ud.synchronize()
    }).disposed(by: bag)
  }
  
  func prepare() {
    MASShortcutBinder.shared().bindShortcut(withDefaultsKey: Key.ShortcutKey) { [weak self] in
      guard let s = self else { return }
      guard let node = s.node else { return }
      s.workspace.value.select()
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
  let workspace: Variable<WorkspaceModel>
  var node: NodeModel? {
    didSet {
      let ud = UserDefaults.standard
      ud.set(node?.id, forKey: Key.NodeId)
      ud.synchronize()
    }
  }
}
