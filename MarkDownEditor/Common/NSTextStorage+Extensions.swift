//
//  NSTextStorage+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/15.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

extension NSTextStorage {
  func highlightMarkdownSyntax() {
    let allRange = NSRange(location: 0, length: length)
    addAttribute(.foregroundColor, value: NSColor.text, range: allRange)
    addAttribute(.underlineStyle, value: NSUnderlineStyle.styleNone.rawValue, range: allRange)
    highlightLinks()
    highlightLists()
    highlightHeads()
    highlightCodes()
  }
  
  private func highlightLists() {
    for range in string.oldRanges(with: "(^|\\n)[\\t ]*(([\\-\\+\\*]|\\d+\\.)( \\[[x ]\\]|)|>+) ") {
      addAttribute(.foregroundColor, value: NSColor.list, range: range)
    }
  }
  
  private func highlightHeads() {
    for range in string.oldRanges(with: "(^|\\n)#+ .*") {
      addAttribute(.foregroundColor, value: NSColor.head, range: range)
    }
  }
  
  private func highlightLinks() {
    for range in string.oldRanges(with: "!?\\[[.[^\\]]]*\\]\\([.[^\\)\\n]]*\\)") {
      addAttribute(.underlineColor, value: NSColor.text, range: range)
      addAttribute(.underlineStyle, value: NSUnderlineStyle.patternDot.rawValue | NSUnderlineStyle.styleSingle.rawValue, range: range)
    }
  }
  
  private func highlightCodes() {
    for range in string.oldRanges(with: "`[.[^`\\n]]+`") + string.oldRanges(with: "```[.\\n[^`]]*\\n```") {
      addAttribute(.foregroundColor, value: NSColor.code, range: range)
    }
  }
}

extension NSColor {
  fileprivate static let list = NSColor(named: Name("List"))!
  fileprivate static let head = NSColor(named: Name("Head"))!
  fileprivate static let code = NSColor(named: Name("Code"))!
}
