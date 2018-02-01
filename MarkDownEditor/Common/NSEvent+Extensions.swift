//
//  NSEvent+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/13.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

extension NSEvent {
  func isPushed(_ keyCode: KeyCode) -> Bool {
    return self.keyCode == keyCode.rawValue
  }
  
  func isPressModifierFlags(only flag: NSEvent.ModifierFlags) -> Bool {
    return modifierFlags.intersection(.deviceIndependentFlagsMask) == flag
  }
}
