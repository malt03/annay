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
    
    workspace.urlObservable.subscribe(onNext: { [weak self] _ in
      guard let s = self else { return }
      NSFileCoordinator.removeFilePresenter(s)
      NSFileCoordinator.addFilePresenter(s)
    }).disposed(by: bag)
  }
  
  func destroy() {
    NSFileCoordinator.removeFilePresenter(self)
  }
  
  var presentedItemURL: URL? {
    // workspace.urlだと上手く検知できないっぽい
    return workspace.url.deletingLastPathComponent()
  }
  
  let presentedItemOperationQueue = OperationQueue()
  
  func presentedSubitemDidChange(at url: URL) {
    if !url.isEqualIgnoringLastSlash(workspace.url) { return }
    if !FileManager.default.fileExists(atPath: url.path) { return }
    // メインスレッドで動かす
    DispatchQueue.main.async { self.workspace.changeDetected() }
  }
}
