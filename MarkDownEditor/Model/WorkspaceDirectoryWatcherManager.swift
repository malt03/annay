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
  
  private(set) var confirm: NodeModel.ConfirmUpdateNote?
  private var watchers = [WorkspaceDirectoryWatcher]()
  
  func prepare(confirm: @escaping NodeModel.ConfirmUpdateNote) {
    self.confirm = confirm
    WorkspaceModel.observableSpaces.distinctUntilChanged({ Set($0.map { $0.id }) == Set($1.map { $0.id }) }).subscribe(onNext: { [weak self] (models) in
      guard let s = self else { return }
      for oldWatcher in s.watchers { oldWatcher.destroy() }
      s.watchers = models.map { WorkspaceDirectoryWatcher(workspace: $0) }
    }).disposed(by: bag)
  }
}
