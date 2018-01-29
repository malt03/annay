//
//  WorkspaceDirectoryWatcherManager.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/29.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation
import RxSwift

final class WorkspaceDirectoryWatcherManager {
  private let bag = DisposeBag()
  
  private init() {}
  
  static let shared = WorkspaceDirectoryWatcherManager()
  
  private let watchers = Variable<[WorkspaceDirectoryWatcher]>([])
  
  func prepare() {
    WorkspaceModel.spaces.asObservable().map {
      $0.map { WorkspaceDirectoryWatcher(workspace: $0) }
    }.bind(to: watchers).disposed(by: bag)
  }
}
