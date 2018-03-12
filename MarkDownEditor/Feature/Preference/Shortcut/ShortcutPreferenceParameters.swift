//
//  ShortcutPreferenceParameters.swift
//  Annay
//
//  Created by Koji Murata on 2018/03/12.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation
import Magnet

@objc protocol ShortcutPreferenceParameters {
  var kindRawValue: String { get }
  var keyCombo: KeyCombo? { get set }
  func perform()
}

extension ShortcutPreferenceParameters {
  func setKeyCombo(_ keyCombo: KeyCombo?) {
    self.keyCombo = keyCombo
    register()
  }
  
  func register() {
    HotKeyCenter.shared.unregisterHotKey(with: kindRawValue)
    guard let keyCombo = keyCombo else { return }
    HotKey(identifier: kindRawValue, keyCombo: keyCombo, target: self as AnyObject, action: #selector(perform)).register()
  }
}
