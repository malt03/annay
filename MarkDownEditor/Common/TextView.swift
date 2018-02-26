//
//  TextView.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/09.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift

final class TextView: NSTextView {
  private let bag = DisposeBag()
  
  private let _isFirstResponder = Variable<Bool>(false)
  var isFirstResponder: Observable<Bool> { return _isFirstResponder.asObservable() }
  var isFirstResponderValue: Bool { return _isFirstResponder.value }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    FontManager.shared.font.subscribe(onNext: { [weak self] (font) in
      self?.font = font
    }).disposed(by: bag)

    textColor = .text
    textContainerInset = NSSize(width: 10, height: 10)
    insertionPointColor = .text
    let style = NSMutableParagraphStyle()
    style.lineSpacing = 4
    defaultParagraphStyle = style
  }

  override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
    if sender.draggingPasteboard().replaceNoteToMarkdown() {
      return super.performDragOperation(sender)
    }
    
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
    do {
      let imageTexts: [String] = try imagesData.flatMap { (imageData) in
        let url = try ResourceManager.save(data: imageData, fileExtension: fileExtension)
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
  
  override func becomeFirstResponder() -> Bool {
    let should = super.becomeFirstResponder()
    if should { _isFirstResponder.value = true }
    return should
  }
  
  override func resignFirstResponder() -> Bool {
    let should = super.resignFirstResponder()
    if should { _isFirstResponder.value = false }
    return should
  }
}
