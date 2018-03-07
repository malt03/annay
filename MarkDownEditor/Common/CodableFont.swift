//
//  CodableFont.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/03/06.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

struct CodableFont: Codable, Equatable {
  private let name: String
  private let size: CGFloat
  
  init(_ font: NSFont) {
    name = font.fontName
    size = font.pointSize
  }
  
  var font: NSFont { return NSFont(name: name, size: size) ?? NSFont.systemFont(ofSize: size) }
}
