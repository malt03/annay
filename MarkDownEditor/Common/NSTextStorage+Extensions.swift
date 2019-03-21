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
    addAttribute(.foregroundColor, value: NSColor.textColor, range: allRange)
    addAttribute(.underlineStyle, value: NSUnderlineStyle.styleNone.rawValue, range: allRange)
    highlightLinks()
    highlightLists()
    highlightHeads()
    highlightCodes()
  }
  
  private func highlightLists() {
    for range in string.oldRanges(with: "(^|\\n)[\\t ]*(([\\-\\+\\*]|\\d+\\.)( \\[[x ]\\]|)|>+) ") {
      addAttribute(.foregroundColor, value: NSColor.controlAccentColor, range: range)
    }
  }
  
  private func highlightHeads() {
    for range in string.oldRanges(with: "(^|\\n)#+ .*") {
      addAttribute(.foregroundColor, value: NSColor.controlAccentColor, range: range)
    }
  }
  
  private func highlightLinks() {
    for range in string.oldRanges(with: "!?\\[[.[^\\]]]*\\]\\([.[^\\)\\n]]*\\)") {
      addAttribute(.underlineColor, value: NSColor.linkColor, range: range)
      addAttribute(.underlineStyle, value: NSUnderlineStyle.patternDot.rawValue | NSUnderlineStyle.styleSingle.rawValue, range: range)
      addAttribute(.foregroundColor, value: NSColor.linkColor, range: range)
    }
  }
  
  private func highlightCodes() {
    for range in string.oldRanges(with: "`[.[^`\\n]]+`") + string.oldRanges(with: "```[.\\n[^`]]*\\n```") {
      addAttribute(.foregroundColor, value: NSColor.controlAccentColor, range: range)
    }
  }
}
