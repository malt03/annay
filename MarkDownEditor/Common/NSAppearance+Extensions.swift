//
//  NSAppearance+Extensions.swift
//  Annay
//
//  Created by Koji Murata on 2019/03/21.
//  Copyright © 2019 Koji Murata. All rights reserved.
//

import Cocoa

extension NSAppearance {
  var isDark: Bool {
    return bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
  }
  
  static var effective: NSAppearance {
    return NSApplication.shared.windows.first?.effectiveAppearance ?? .current
  }
}
