//
//  BookmarkManager.swift
//  Annay
//
//  Created by Koji Murata on 2019/03/22.
//  Copyright © 2019 Koji Murata. All rights reserved.
//

import Cocoa

final class BookmarkManager {
  private struct Key {
    static func Data(for url: URL) -> String {
      return "BookmarkManager/Data\(url.appendingPathComponent("x").standardizedFileURL.path)"
    }
  }
  
  static let shared = BookmarkManager()
  
  func getBookmarkedURL(_ url: URL, fallback: () -> URL?, handler: (_ url: URL) throws -> Void) rethrows {
    var subURL = url
    var components = [String]()
    
    while subURL.path.count > 1 {
      if let data = UserDefaults.standard.data(forKey: Key.Data(for: subURL)) {
        var isStale = false
        guard let bookmarkedURL = try? URL.init(resolvingBookmarkData: data, options: [.withSecurityScope, .withoutUI], bookmarkDataIsStale: &isStale) else {
          NSAlert(error: MarkDownEditorError.couldNotAccessFile(url: url)).runModal()
          if let fallbackURL = fallback() { try handler(fallbackURL) }
          return
        }
        if isStale {
          NSAlert(error: MarkDownEditorError.couldNotAccessFile(url: url)).runModal()
          if let fallbackURL = fallback() { try handler(fallbackURL) }
          return
        }
        var absoluteURL = bookmarkedURL
        for component in components {
          absoluteURL.appendPathComponent(component)
        }
        _ = bookmarkedURL.startAccessingSecurityScopedResource()
        try handler(absoluteURL)
        bookmarkedURL.stopAccessingSecurityScopedResource()
        return
      } else {
        components.insert(subURL.lastPathComponent, at: 0)
        subURL = subURL.deletingLastPathComponent()
      }
    }
    
    if let fallbackURL = fallback() { try handler(fallbackURL) }
  }
  
  func bookmark(url: URL) {
    let data = try! url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
    UserDefaults.standard.set(data, forKey: Key.Data(for: url))
    UserDefaults.standard.synchronize()
  }
}
