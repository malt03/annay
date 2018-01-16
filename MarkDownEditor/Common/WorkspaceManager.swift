//
//  WorkspaceManager.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/17.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation
import RxSwift

final class WorkspaceManager {
  private struct Key {
    static let Workspace = "WorkspaceManager/Workspace"
  }
  
  private static var workspace: URL? {
    get { return UserDefaults.standard.url(forKey: Key.Workspace) }
    set {
      let ud = UserDefaults.standard
      ud.set(newValue, forKey: Key.Workspace)
      ud.synchronize()
    }
  }

  static let shared = WorkspaceManager()

  let workspace: BehaviorSubject<URL?>
  let workspaceString: Observable<String?>
  
  private init() {
    workspace = BehaviorSubject<URL?>(value: WorkspaceManager.workspace)
    workspaceString = workspace.map { $0?.path.replacingOccurrences(of: NSHomeDirectory(), with: "~") }
  }
  
  func updateWorkspace(_ url: URL) {
    WorkspaceManager.workspace = url
    workspace.onNext(url)
  }
}
