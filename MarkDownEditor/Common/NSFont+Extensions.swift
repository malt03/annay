//
//  NSFont+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/10.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

extension NSFont {
  var displayNameWithPoint: String? {
    guard let displayName = displayName else { return nil }
    return "\(displayName) \(String(format: "%.0f", pointSize)) pt."
  }
}
