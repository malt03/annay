//
//  NSImage+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/28.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

extension NSImage {
  func tinted(_ tintColor: NSColor) -> NSImage {
    if isTemplate == false {
      return self
    }
    
    let image = self.copy() as! NSImage
    image.lockFocus()
    
    tintColor.set()
    NSRect(origin: .zero, size: image.size).fill(using: .sourceAtop)
    
    image.unlockFocus()
    image.isTemplate = false
    
    return image
  }
}
