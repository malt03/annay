//
//  WorkspaceDirectoryWatcher.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/29.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation
import RxSwift
import RealmSwift

final class WorkspaceDirectoryWatcher: NSObject, NSFilePresenter {
  private let bag = DisposeBag()
  
  private let workspace: WorkspaceModel
  
  init(workspace: WorkspaceModel) {
    self.workspace = workspace
    super.init()
    
    workspace.directoryUrlObservable.subscribe(onNext: { [weak self] _ in
      guard let s = self else { return }
      NSFileCoordinator.removeFilePresenter(s)
      NSFileCoordinator.addFilePresenter(s)
    }).disposed(by: bag)
  }
  
  func destroy() {
    NSFileCoordinator.removeFilePresenter(self)
  }
  
  var presentedItemURL: URL? {
    return workspace.directoryUrl
  }
  
  let presentedItemOperationQueue = OperationQueue()
  
  func presentedSubitemDidChange(at url: URL) {
    if !url.isEqualIgnoringLastSlash(workspace.directoryUrl) { return }
    if !FileManager.default.fileExists(atPath: url.path) { return }
    // メインスレッドで動かす
    guard let confirm = WorkspaceDirectoryWatcherManager.shared.confirm else { return }
    DispatchQueue.main.async {
      Realm.transaction { (realm) in
        alertError { try self.workspace.updateIndex(confirmUpdateNote: confirm, realm: realm) }
      }
    }
  }
}
