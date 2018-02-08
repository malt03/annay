//
//  PreferenceWindowController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/07.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class PreferenceWindowController: NSWindowController {
  private static let shared = NSStoryboard(name: NSStoryboard.Name(rawValue: "Preference"), bundle: .main).instantiateInitialController() as! PreferenceWindowController
  
  static func show() {
    shared.show()
  }
  
  static func hide() {
    shared.hide()
  }
  
  private var windowShowing = false
  
  private func showWindowIfNeeded() -> Bool {
    if windowShowing { return false }
    windowShowing = true
    showWindow(nil)
    return true
  }
  
  private func show() {
    if showWindowIfNeeded() { return }
    window?.orderFront(nil)
    window?.makeKey()
  }
  
  private func hide() {
    window?.orderOut(nil)
  }
  
  private func toggle() {
    if showWindowIfNeeded() { return }
    guard let window = window else { return }
    if window.isVisible {
      hide()
    } else {
      show()
    }
  }
}
