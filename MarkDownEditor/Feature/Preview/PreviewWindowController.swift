//
//  PreviewWindowController.swift
//  Annay
//
//  Created by Koji Murata on 2019/07/27.
//  Copyright © 2019 Koji Murata. All rights reserved.
//

import Cocoa

final class PreviewWindowController: NSWindowController {
  private static let shared = NSStoryboard(name: "Preview", bundle: .main).instantiateInitialController() as! PreviewWindowController
  
  static func show(fullScreen: Bool) {
    shared.show(fullScreen: fullScreen)
  }
  
  private var windowShowing = false

  private func showWindowIfNeeded() -> Bool {
    if windowShowing { return false }
    windowShowing = true
    showWindow(nil)
    return true
  }
  
  private func show(fullScreen: Bool) {
    defer {
      if fullScreen {
        window?.toggleFullScreen(nil)
      }
    }

    if showWindowIfNeeded() { return }
    window?.orderFront(nil)
    window?.makeKey()
  }
}
