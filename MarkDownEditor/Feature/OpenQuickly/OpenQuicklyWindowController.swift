//
//  OpenQuicklyWindowController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/28.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class OpenQuicklyWindowController: NSWindowController {
  private static let shared = NSStoryboard(name: NSStoryboard.Name(rawValue: "OpenQuickly"), bundle: .main).instantiateInitialController() as! OpenQuicklyWindowController
  
  static func show() {
    shared.show()
  }
  
  static func hide() {
    shared.hide()
  }

  static func toggle() {
    shared.toggle()
  }
  
  private var windowShowing = false
  
  private func showWindowIfNeeded() -> Bool {
    if windowShowing { return false }
    windowShowing = true
    showWindow(nil)
    window?.acceptsMouseMovedEvents = true
    return true
  }
  
  private func show() {
    if showWindowIfNeeded() { return }
    window?.orderFront(nil)
    window?.makeKey()
    window?.acceptsMouseMovedEvents = true
  }
  
  private func hide() {
    window?.orderOut(nil)
    window?.acceptsMouseMovedEvents = false
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
  
  override func windowDidLoad() {
    super.windowDidLoad()
    window?.isMovable = false
    window?.center()
    window?.delegate = self
  }
}

extension OpenQuicklyWindowController: NSWindowDelegate {
  func windowDidResignKey(_ notification: Notification) {
    hide()
  }
}
