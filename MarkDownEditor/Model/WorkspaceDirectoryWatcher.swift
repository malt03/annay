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
  
  private let workspaceId: String
  private var workspace: WorkspaceModel {
    return Realm.instance.objects(WorkspaceModel.self).filter("id = %@", workspaceId).first!
  }
  
  private var startAccessingUrl: URL?
  
  init(workspace: WorkspaceModel) {
    self.workspaceId = workspace.id
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
  
  deinit {
    startAccessingUrl?.stopAccessingSecurityScopedResource()
  }
  
  var presentedItemURL: URL? {
    let url = workspace.directoryUrl
    let bookmarkedUrl = BookmarkManager.shared.getBookmarkedURLWithoutStartAccessing(url, fallback: { url })
    
    startAccessingUrl?.stopAccessingSecurityScopedResource()
    startAccessingUrl = nil
    
    if let bookmarked = bookmarkedUrl.bookmarked {
      if bookmarked.startAccessingSecurityScopedResource() {
        startAccessingUrl = bookmarked
      }
    }
    
    return bookmarkedUrl.main
  }
  
  let presentedItemOperationQueue = OperationQueue()
  
  func presentedSubitemDidChange(at url: URL) {
    guard let confirm = WorkspaceDirectoryWatcherManager.shared.confirm else { return }
    // メインスレッドで動かす
    DispatchQueue.main.async {
      Realm.transaction { (realm) in
        alertError { try self.workspace.updateIndex(confirmUpdateNote: confirm, realm: realm) }
      }
    }
  }
}
