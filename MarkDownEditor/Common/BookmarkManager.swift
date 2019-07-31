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
  
  struct BookmarkedURL {
    let main: URL
    let bookmarked: URL?
  }
  
  static let shared = BookmarkManager()
  
  func getBookmarkedURL(_ url: URL, fallback: () -> URL, handler: (_ url: URL) throws -> Void) rethrows {
    let bookmarkedUrl = getBookmarkedURLWithoutStartAccessing(url, fallback: fallback)
    
    _ = bookmarkedUrl.bookmarked?.startAccessingSecurityScopedResource()
    try handler(bookmarkedUrl.main)
    bookmarkedUrl.bookmarked?.stopAccessingSecurityScopedResource()
  }
  
  func getBookmarkedURLWithoutStartAccessing(_ url: URL, fallback: () -> URL) -> BookmarkedURL {
    var subURL = url
    var components = [String]()
    
    while subURL.path.count > 1 {
      if let data = UserDefaults.standard.data(forKey: Key.Data(for: subURL)) {
        var isStale = false
        guard let bookmarkedURL = try? URL(resolvingBookmarkData: data, options: [.withSecurityScope, .withoutUI], bookmarkDataIsStale: &isStale) else {
          NSAlert(error: MarkDownEditorError.couldNotAccessFile(url: url)).runModal()
          return BookmarkedURL(main: fallback(), bookmarked: nil)
        }
        if isStale {
          NSAlert(error: MarkDownEditorError.couldNotAccessFile(url: url)).runModal()
          return BookmarkedURL(main: fallback(), bookmarked: nil)
        }
        var absoluteURL = bookmarkedURL
        for component in components {
          absoluteURL.appendPathComponent(component)
        }
        return BookmarkedURL(main: absoluteURL, bookmarked: bookmarkedURL)
      } else {
        components.insert(subURL.lastPathComponent, at: 0)
        subURL = subURL.deletingLastPathComponent()
      }
    }
    
    return BookmarkedURL(main: fallback(), bookmarked: nil)
  }
  
  func bookmark(url: URL) {
    let data = try! url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
    UserDefaults.standard.set(data, forKey: Key.Data(for: url))
    UserDefaults.standard.synchronize()
  }
}
