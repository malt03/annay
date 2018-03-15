//
//  NSPasteboard+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/15.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

extension NSPasteboard {
  var nodes: [NodeModel] {
    guard let workspace = parentWorkspace else { return [] }
    return (pasteboardItems ?? []).compactMap { (item) -> NodeModel? in
      guard let id = item.string(forType: .nodeModel) else { return nil }
      return NodeModel.node(for: id, for: workspace)
    }
  }
  
  var parentWorkspace: WorkspaceModel? {
    guard let workspaceUniqId = string(forType: .parentWorkspaceModel) else { return nil }
    return WorkspaceModel.spaces.value.first(where: { $0.uniqId == workspaceUniqId })
  }
  
  func relaceLinkToMarkdown() -> Bool {
    if replaceFileURLsToMarkdown() { return true }
    if replaceLinkObjectToMarkdown() { return true }
    if replaceURLToMarkdown() { return true }
    return false
  }
  
  private func replaceFileURLsToMarkdown() -> Bool {
    let texts = (pasteboardItems ?? []).compactMap { (item) -> String? in
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
    let linkTexts = (pasteboardItems ?? []).compactMap { (item) -> String? in
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
  
  func becomeOnlyPlaneText() {
    let planeText = string(forType: .string) ?? ""
    clearContents()
    setString(planeText, forType: .string)
  }
  
  func replaceNoteToMarkdown() -> Bool {
    guard let parentWorkspaceId = string(forType: .parentWorkspaceModel) else { return false }
    let notes = nodes.filter { !$0.isDirectory }
    if notes.count == 0 { return false }
    clearContents()
    let linkTexts = notes.map { "[\($0.name)](annay:///\(parentWorkspaceId)/\($0.id))" }
    writeObjects(linkTexts as [NSPasteboardWriting])
    return true
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
    do {
      let imageTexts: [String] = try imagesData.compactMap { (imageData) in
        let url = try ResourceManager.save(data: imageData, fileExtension: fileExtension)
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
    return images.compactMap { (image) in
      guard
        let imageData = image.tiffRepresentation,
        let imageRep = NSBitmapImageRep(data: imageData),
        let fileData = imageRep.representation(using: .png, properties: [:])
        else { return nil }
      return fileData
    }
  }
  
  var pngImagesData: [Data] {
    return pasteboardItems?.compactMap { $0.data(forType: .png) } ?? []
  }
  
  var gifImagesData: [Data] {
    return pasteboardItems?.compactMap { $0.data(forType: NSPasteboard.PasteboardType(kUTTypeGIF as String)) } ?? []
  }
}
