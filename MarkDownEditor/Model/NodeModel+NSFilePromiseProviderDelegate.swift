//
//  NodeModel+NSFilePromiseProviderDelegate.swift
//  Annay
//
//  Created by Koji Murata on 2018/03/28.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

extension NodeModel: NSFilePromiseProviderDelegate {
  func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
    if isDirectory {
      return name
    } else {
      return name + ".md"
    }
  }
  
  func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL, completionHandler: @escaping (Error?) -> Void) {
    do {
      try write(to: url, as: .text)
    } catch {
      NSAlert(error: error).runModal()
      completionHandler(error)
      return
    }
    completionHandler(nil)
  }
}
