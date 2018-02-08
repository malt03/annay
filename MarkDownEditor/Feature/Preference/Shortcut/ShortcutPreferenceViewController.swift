//
//  ShortcutPreferenceViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/08.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class ShortcutPreferenceViewController: NSViewController {
  override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
    defer { super.prepare(for: segue, sender: sender) }
    
    guard let vc = segue.destinationController as? NewOrOpenNoteShortcutPreferenceViewController else { return }
    switch segue.identifier?.rawValue ?? "" {
    case "NewNote": vc.prepare(kind: .new)
    default:
      break
    }
  }
}
