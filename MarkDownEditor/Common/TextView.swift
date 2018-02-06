//
//  TextView.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/09.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class TextView: NSTextView {
  override func awakeFromNib() {
    super.awakeFromNib()
    font = NSFont(name: "Osaka-Mono", size: 14)
    textColor = .text
    textContainerInset = NSSize(width: 10, height: 10)
    insertionPointColor = .text
    let style = NSMutableParagraphStyle()
    style.lineSpacing = 4
    defaultParagraphStyle = style
  }

  override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
    if sender.draggingPasteboard().replaceImagesToMarkdown() {
      return super.performDragOperation(sender)
    }
    
    if sender.draggingPasteboard().relaceLinkToMarkdown() {
      return super.performDragOperation(sender)
    }

    return super.performDragOperation(sender)
  }
  
  private func writeImages(_ imagesData: [Data], fileExtension: String, sender: NSDraggingInfo) -> Bool {
    let pasteboard = sender.draggingPasteboard()
    let imageDirectory = WorkspaceModel.selected.value.sourceDirectory.appendingPathComponent("images", isDirectory: true)
    do {
      try FileManager.default.createDirectoryIfNeeded(url: imageDirectory)
      let imageTexts: [String] = try imagesData.flatMap { (imageData) in
        let url = imageDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(fileExtension)
        try imageData.write(to: url)
        return "![image](\(url.absoluteString))"
      }
      pasteboard.clearContents()
      pasteboard.writeObjects(imageTexts as [NSPasteboardWriting])
      return super.performDragOperation(sender)
    } catch {
      NSAlert(error: error).runModal()
      return false
    }
  }
}
