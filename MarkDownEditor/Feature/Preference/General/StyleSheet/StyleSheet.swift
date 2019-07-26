//
//  StyleSheet.swift
//  Annay
//
//  Created by Koji Murata on 2018/03/13.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation

struct StyleSheet: Hashable {
  private(set) var css: String
  let name: String
  
  let fileUrl: URL
  
  func hash(into hasher: inout Hasher) {
    fileUrl.hash(into: &hasher)
  }
  
  func select() {
    GeneralPreference.shared.styleSheetName.accept(name)
  }
  
  mutating func reload() {
    var newCSS = css
    BookmarkManager.shared.getBookmarkedURL(fileUrl, fallback: { fileUrl }) { (bookmarkedURL) in
      newCSS = try! String(contentsOf: bookmarkedURL)
    }
    css = newCSS
  }
  
  init?(file: URL) {
    if file.pathExtension != "css" { return nil }
    fileUrl = file
    name = file.lastPathComponent
    
    var savedCSS: String?
    BookmarkManager.shared.getBookmarkedURL(file, fallback: { file }) { (bookmarkedURL) in
      savedCSS = try! String(contentsOf: bookmarkedURL)
    }
    if let savedCSS = savedCSS {
      css = savedCSS
    } else {
      return nil
    }
  }
}
