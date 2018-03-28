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
    return name
  }
  
  func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL, completionHandler: @escaping (Error?) -> Void) {
    do {
      try write(to: url, as: .text)
    } catch {
      completionHandler(error)
    }
    completionHandler(nil)
  }
  
  func write(
    to url: URL,
    as type: NodeModelExporter.ExportType,
    selectAndWriteEnqueueHandler: ((NodeModelExporter.QueueItem) -> Void) = { _ in }
  ) throws {
    if isDirectory {
      try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
      for child in sortedChildren(query: nil) {
        try child.write(to: url.appendingPathComponent(child.name), as: type, selectAndWriteEnqueueHandler: selectAndWriteEnqueueHandler)
      }
    } else {
      switch type {
      case .html:
        guard let html = HtmlDataStore.shared.html(for: id) else {
          selectAndWriteEnqueueHandler((self, url))
          return
        }
        try html.write(to: url.appendingPathExtension("html"), atomically: true, encoding: .utf8)
      case .text:
        try (body.data(using: .utf8) ?? Data()).write(to: url.appendingPathExtension("md"))
      }
    }
  }
}
