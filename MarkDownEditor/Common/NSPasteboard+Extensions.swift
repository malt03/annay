//
//  NSPasteboard+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/15.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

extension NSPasteboard {
  var nodes: [NodeModel]? {
    guard let ids = string(forType: .nodeModel) else { return nil }
    return ids.split(separator: "\n").flatMap { NodeModel.node(for: String($0)) }
  }
  
  func relaceLinkToMarkdown() -> Bool {
    if replaceFileURLsToMarkdown() { return true }
    if replaceLinkObjectToMarkdown() { return true }
    if replaceURLToMarkdown() { return true }
    return false
  }
  
  private func replaceFileURLsToMarkdown() -> Bool {
    let texts = (pasteboardItems ?? []).flatMap { (item) -> String? in
      guard let url = URL(string: item.string(forType: .fileURL) ?? "") else { return nil }
      if url.isConformsToUTI("public.image") {
        return "![\(url.name)](\(url.absoluteString))"
      } else {
        return "[\(url.name)](\(url.absoluteString))"
      }
    }
    if texts.count > 0 {
      clearContents()
      writeObjects(texts as [NSPasteboardWriting])
      return true
    }
    return false
  }
  
  private func replaceURLToMarkdown() -> Bool {
    if canReadObject(forClasses: [NSURL.self], options: nil) {
      let urls = (readObjects(forClasses: [NSURL.self], options: nil) as? [URL]) ?? []
      let texts = urls.map { "<\($0.absoluteString)>" }
      clearContents()
      writeObjects(texts as [NSPasteboardWriting])
      return true
    }
    return false
  }
  
  private func replaceLinkObjectToMarkdown() -> Bool {
    let linkTexts = (pasteboardItems ?? []).flatMap { (item) -> String? in
      guard
        let name = item.string(forType: NSPasteboard.PasteboardType("public.url-name")),
        let url = URL(string: item.string(forType: .string) ?? "")
        else { return nil }
      return "[\(name)](\(url.absoluteString))"
    }
    if linkTexts.count > 0 {
      clearContents()
      writeObjects(linkTexts as [NSPasteboardWriting])
      return true
    }
    return false
  }
 
  func replaceImagesToMarkdown() -> Bool {
    do {
      let imagesData = gifImagesData
      if imagesData.count > 0 { return replaceImagesDataToMarkdown(imagesData, fileExtension: "gif") }
    }
    do {
      let imagesData = pngImagesData
      if imagesData.count > 0 { return replaceImagesDataToMarkdown(imagesData, fileExtension: "png") }
    }
    do {
      let imagesData = imagesDataRepresentationUsingPNG
      if imagesData.count > 0 { return replaceImagesDataToMarkdown(imagesData, fileExtension: "png") }
    }
    return false
  }
  
  private func replaceImagesDataToMarkdown(_ imagesData: [Data], fileExtension: String) -> Bool {
    let imageDirectory = WorkspaceModel.selected.value.sourceDirectory.appendingPathComponent("images", isDirectory: true)
    do {
      try FileManager.default.createDirectoryIfNeeded(url: imageDirectory)
      let imageTexts: [String] = try imagesData.flatMap { (imageData) in
        let url = imageDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(fileExtension)
        try imageData.write(to: url)
        return "![image](\(url.absoluteString))"
      }
      clearContents()
      writeObjects(imageTexts as [NSPasteboardWriting])
      return true
    } catch {
      NSAlert(error: error).runModal()
      return false
    }
  }
  
  var imagesDataRepresentationUsingPNG: [Data] {
    if !canReadObject(forClasses: [NSImage.self], options: nil) { return [] }
    let images = (readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage]) ?? []
    return images.flatMap { (image) in
      guard
        let imageData = image.tiffRepresentation,
        let imageRep = NSBitmapImageRep(data: imageData),
        let fileData = imageRep.representation(using: .png, properties: [:])
        else { return nil }
      return fileData
    }
  }
  
  var pngImagesData: [Data] {
    return pasteboardItems?.flatMap { $0.data(forType: .png) } ?? []
  }
  
  var gifImagesData: [Data] {
    return pasteboardItems?.flatMap { $0.data(forType: NSPasteboard.PasteboardType(kUTTypeGIF as String)) } ?? []
  }
}
