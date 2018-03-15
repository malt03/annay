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
  
  var hashValue: Int { return fileUrl.hashValue }
  
  func select() {
    GeneralPreference.shared.styleSheetName.value = name
  }
  
  mutating func reload() {
    do {
      css = try String(contentsOf: fileUrl)
    } catch {}
  }
  
  init?(file: URL) {
    if file.pathExtension != "css" { return nil }
    fileUrl = file
    do {
      name = file.lastPathComponent
      css = try String(contentsOf: file)
    } catch {
      return nil
    }
  }
}
