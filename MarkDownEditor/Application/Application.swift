//
//  Application.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/01.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift

final class Application: NSApplication, NSFontChanging {
  @IBOutlet private weak var navigateMenu: NSMenu!
  private var commandNFlag = false
  
  let isEnabled = Variable(true)
  
  override func sendEvent(_ event: NSEvent) {
    if !isEnabled.value { return }
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

  func changeFont(_ sender: NSFontManager?) {
    guard let manager = sender as? NSFontManager else { return }
    GeneralPreference.shared.convert(with: manager)
  }
  
  private var workspaceMenus = [NSMenuItem]()
  
  func prepareForWorkspaces() {
    _ = WorkspaceModel.observableSpaces.subscribe(onNext: { (spaces) in
      var newWorkspaceMenus = spaces.enumerated().compactMap { (index, space) -> NSMenuItem? in
        if index >= 9 { return nil }
        let title = String(format: Localized("Select \"%@\""), space.nameValue)
        let item = NSMenuItem(title: title, action: #selector(self.selectWorkspace(_:)), keyEquivalent: "\(index + 1)")
        item.keyEquivalentModifierMask = .command
        item.tag = index
        return item
      }
      if newWorkspaceMenus.count > 0 { newWorkspaceMenus = [NSMenuItem.separator()] + newWorkspaceMenus }
      for oldMenu in self.workspaceMenus { self.navigateMenu.removeItem(oldMenu) }
      for newMenu in newWorkspaceMenus { self.navigateMenu.addItem(newMenu) }
      self.workspaceMenus = newWorkspaceMenus
    })
  }
  
  @objc private func selectWorkspace(_ sender: NSMenuItem) {
    WorkspaceModel.spaces[sender.tag].select()
  }
}
