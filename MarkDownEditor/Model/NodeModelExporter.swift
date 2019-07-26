//
//  NodeModelExporter.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/27.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class NodeModelExporter {
  enum ExportType {
    case html
    case text
  }
  
  typealias SelectAndWriteQueue = Queue<QueueItem>
  typealias QueueItem = (NodeModel, URL)
  typealias CompletionHandler = (_ urls: [URL]) -> Void
  
  private var selectAndWriteQueue = SelectAndWriteQueue()
  private var lastDequeuedItem: QueueItem?
  
  private let exportType: ExportType
  private let nodes: [NodeModel]
  private let completionHandler: CompletionHandler
  
  private var strongSelf: NodeModelExporter?
  private var urls = [URL]()

  init(type: ExportType, nodes: [NodeModel], completionHandler: @escaping CompletionHandler) {
    exportType = type
    self.nodes = nodes
    self.completionHandler = completionHandler
  }
  
  deinit {
    completionHandler(urls)
  }

  func export() {
    strongSelf = self
    
    let openPanel = NSOpenPanel()
    openPanel.allowsMultipleSelection = false
    openPanel.canChooseDirectories = true
    openPanel.canCreateDirectories = true
    openPanel.canChooseFiles = false
    openPanel.prompt = Localized("Export")
    openPanel.begin { [unowned self] (result) in
      if result != .OK { return }
      guard let url = openPanel.url else { return }
      alertError {
        for node in self.nodes {
          if let url = try node.export(in: url, type: self.exportType, selectAndWriteQueue: &self.selectAndWriteQueue) {
            self.urls.append(url)
          }
        }
        (NSApplication.shared as! Application).isEnabled.accept(false)
        self.performSelectAndWrite()
      }
    }
  }
  
  private func performSelectAndWrite() {
    guard let item = selectAndWriteQueue.dequeue() else {
      NotificationCenter.default.removeObserver(self)
      (NSApplication.shared as! Application).isEnabled.accept(true)
      strongSelf = nil
      return
    }
    
    lastDequeuedItem = item
    let (node, _) = item
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(storedHtmlData(_:)),
      name: .StoredHtmlData(nodeId: node.id),
      object: nil
    )
    
    DispatchQueue.main.async {
      node.select()
    }
  }
  
  @objc private func storedHtmlData(_ notification: Notification) {
    defer { performSelectAndWrite() }
    guard let (node, url) = lastDequeuedItem else { return }
    NotificationCenter.default.removeObserver(self, name: .StoredHtmlData(nodeId: node.id), object: nil)
    do {
      try node.write(to: url, as: exportType)
    } catch {
      NSAlert(error: error).runModal()
    }
  }
}
