//
//  WorkspaceDirectoryWatcher.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/29.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift

final class WorkspaceDirectoryWatcher: NSObject, NSFilePresenter {
  private let bag = DisposeBag()
  
  private let workspace: WorkspaceModel
  
  init(workspace: WorkspaceModel) {
    self.workspace = workspace
    super.init()
    
    workspace.url.asObservable().subscribe(onNext: { [weak self] _ in
      guard let s = self else { return }
      NSFileCoordinator.removeFilePresenter(s)
      NSFileCoordinator.addFilePresenter(s)
    }).disposed(by: bag)
  }
  
  deinit {
    NSFileCoordinator.removeFilePresenter(self)
  }
  
  var presentedItemURL: URL? {
    return workspace.url.value.deletingLastPathComponent()
  }
  
  let presentedItemOperationQueue = OperationQueue()
  
  func presentedSubitemDidChange(at url: URL) {
    if url.appendingPathComponent("x") != workspace.url.value.appendingPathComponent("x") { return }
    if FileManager.default.fileExists(atPath: url.path) { return }
    DispatchQueue.main.async {
      WorkspaceModel.spaces.value.remove(object: self.workspace)
    }
  }
}
