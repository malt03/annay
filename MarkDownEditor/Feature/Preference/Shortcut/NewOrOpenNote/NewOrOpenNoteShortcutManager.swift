//
//  NewOrOpenNoteShortcutManager.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/08.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import RxSwift
import Foundation
import Magnet

final class NewOrOpenNoteShortcutManager {
  static let shared = NewOrOpenNoteShortcutManager()
  
  private let bag = DisposeBag()
  
  private init() {}
  
  func register(for kind: Kind, keyCombo: KeyCombo) {
    HotKeyCenter.shared.unregisterHotKey(with: kind.rawValue)
    
    let selector: Selector
    switch kind {
    case .new: selector = #selector(newNote)
    case .open: selector = #selector(openNote)
    }
    
    let hotKey = HotKey(identifier: kind.rawValue, keyCombo: keyCombo, target: self, action: selector)
    hotKey.register()
  }
  
  @objc private func newNote() {
    guard let node = node(for: .new), let workspace = workspace(for: .new) else {
      NSAlert(localizedMessageText: "No parent directory was selected.").runModal()
      return
    }
    workspace.select()
    let note = NodeModel.createNote(in: node)
    note.selected()
    NotificationCenter.default.post(name: .MoveFocusToEditor, object: nil)
    Application.shared.activate(ignoringOtherApps: true)
    for handler in insertNodeHandlers {
      handler(note)
    }
  }
  
  @objc private func openNote() {
    guard let node = node(for: .open), let workspace = workspace(for: .open) else {
      NSAlert(localizedMessageText: "No note was selected.").runModal()
      return
    }
    workspace.select()
    node.selected()
    NotificationCenter.default.post(name: .MoveFocusToEditor, object: nil)
    Application.shared.activate(ignoringOtherApps: true)
  }
}
