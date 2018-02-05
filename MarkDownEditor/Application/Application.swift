//
//  Application.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/01.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class Application: NSApplication {
  private var commandNFlag = false
  
  override func sendEvent(_ event: NSEvent) {
    if event.type == .keyDown {
      if commandNFlag {
        commandNFlag = false
        switch KeyCode(rawValue: event.keyCode) ?? .none {
        case .d:
          NotificationCenter.default.post(name: .CreateDirectory, object: nil)
          return
        case .g:
          NotificationCenter.default.post(name: .CreateGroup, object: nil)
          return
        default: break
        }
      } else {
        if event.isPressModifierFlags(only: .option) && event.isPushed(.n) {
          commandNFlag = true
          return
        }
      }
    }
    super.sendEvent(event)
  }
}
