//
//  TextView.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/09.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift
import RxRelay

final class TextView: NSTextView {
  private let bag = DisposeBag()
  
  private let _isFirstResponder = BehaviorRelay(value: false)
  var isFirstResponder: Observable<Bool> { return _isFirstResponder.asObservable() }
  var isFirstResponderValue: Bool { return _isFirstResponder.value }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    GeneralPreference.shared.fontObservable.subscribe(onNext: { [weak self] (font) in
      self?.font = font
    }).disposed(by: bag)

    textColor = .textColor
    textContainerInset = NSSize(width: 10, height: 10)
    insertionPointColor = .textColor
    let style = NSMutableParagraphStyle()
    style.lineSpacing = 4
    defaultParagraphStyle = style
  }

  override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
    sender.draggingPasteboard.replace()
    return super.performDragOperation(sender)
  }
  
  override func paste(_ sender: Any?) {
    pasteAsPlainText(sender)
  }
  
  override func pasteAsPlainText(_ sender: Any?) {
    NSPasteboard.general.replace()
    super.pasteAsPlainText(sender)
  }
  
  private func writeImages(_ imagesData: [Data], fileExtension: String, sender: NSDraggingInfo) -> Bool {
    let pasteboard = sender.draggingPasteboard
    do {
      let imageTexts: [String] = try imagesData.compactMap { (imageData) in
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
    if should { _isFirstResponder.accept(true) }
    return should
  }
  
  override func resignFirstResponder() -> Bool {
    let should = super.resignFirstResponder()
    if should { _isFirstResponder.accept(false) }
    return should
  }
}
