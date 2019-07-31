//
//  StyleSheetFileWatcher.swift
//  Annay
//
//  Created by Koji Murata on 2018/03/13.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift

final class StyleSheetFileWatcher: NSObject, NSFilePresenter {
  private let _fileAddedOrChanged = PublishSubject<URL>()
  private let _fileDeleted = PublishSubject<URL>()
  var fileAddedOrChanged: Observable<URL> { return _fileAddedOrChanged }
  var fileDeleted: Observable<URL> { return _fileDeleted }
  
  private var startAccessingUrl: URL?
  
  override init() {
    super.init()
    NSFileCoordinator.addFilePresenter(self)
  }
  
  var presentedItemURL: URL? {
    let url = PreferenceManager.shared.styleSheetsUrl
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
  
  deinit {
    startAccessingUrl?.stopAccessingSecurityScopedResource()
  }
  
  let presentedItemOperationQueue = OperationQueue()
  
  func presentedSubitemDidChange(at url: URL) {
    DispatchQueue.main.async {
      if FileManager.default.fileExists(atPath: url.path) {
        self._fileAddedOrChanged.onNext(url)
      } else {
        self._fileDeleted.onNext(url)
      }
    }
  }
}
