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

  struct Format {
    let symbol: String
  }
  
  @objc private func bold(_ sender: Any)          { toggleFormat(Format(symbol: "**")) }
  @objc private func italic(_ sender: Any)        { toggleFormat(Format(symbol: "*")) }
  @objc private func strikethrough(_ sender: Any) { toggleFormat(Format(symbol: "~~")) }
  private func toggleFormat(_ format: Format) {
    let range = selectedRange()
    
    if
      let beforeSymbolRange = searchSymbol(before: true, selectedRange: range, symbol: format.symbol),
      let afterSymbolRange = searchSymbol(before: false, selectedRange: range, symbol: format.symbol)
    {
      let newTextRange = NSRange(location: beforeSymbolRange.upperBound, length: afterSymbolRange.lowerBound - beforeSymbolRange.upperBound)
      let newText = (string as NSString).substring(with: newTextRange)
      let rangeWithSymbol = NSRange(location: beforeSymbolRange.lowerBound, length: afterSymbolRange.upperBound - beforeSymbolRange.lowerBound)
      insertText(newText, replacementRange: rangeWithSymbol)
      setSelectedRange(NSRange(location: beforeSymbolRange.lowerBound, length: newTextRange.length))
    } else {
        insertText(format.symbol, replacementRange: NSRange(location: range.upperBound, length: 0))
        insertText(format.symbol, replacementRange: NSRange(location: range.lowerBound, length: 0))
        if range.length == 0 {
            setSelectedRange(NSRange(location: range.location + format.symbol.count, length: 0))
        }
    }
  }
  
  private func searchSymbol(before: Bool, selectedRange: NSRange, symbol: String) -> NSRange? {
    let beginningOfCheckRanges: [Int]
    if before {
      beginningOfCheckRanges = [Int]((selectedRange.lowerBound - symbol.count)...selectedRange.lowerBound)
    } else {
      beginningOfCheckRanges = [Int]((selectedRange.upperBound - symbol.count)...selectedRange.upperBound).reversed()
    }
    
    for beginningOfCheckRange in beginningOfCheckRanges {
      let checkRange = NSRange(location: beginningOfCheckRange, length: symbol.count)
      
      if checkRange.lowerBound >= 0 && checkRange.upperBound <= (string as NSString).length {
        if (string as NSString).substring(with: checkRange) == symbol {
          return checkRange
        }
      }
    }
    return nil
  }
  
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
