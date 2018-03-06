//
//  GeneralPreference.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/03/06.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift

struct GeneralPreference: Codable {
  var isHideEditorWhenUnfocused: Bool
  var font: CodableFont
  
  mutating func convert(with manager: NSFontManager) {
    font = CodableFont(manager.convert(font.font))
  }
  
  func showFontPanel() {
    let fontPanel = NSFontPanel.shared
    fontPanel.setPanelFont(font.font, isMultiple: false)
    fontPanel.makeKeyAndOrderFront(nil)
  }
  
  private init(isHideEditorWhenUnfocused: Bool, font: NSFont) {
    self.isHideEditorWhenUnfocused = isHideEditorWhenUnfocused
    self.font = CodableFont(font)
  }
  
  static var `default`: GeneralPreference {
    return GeneralPreference(isHideEditorWhenUnfocused: false, font: NSFont(name: "Osaka-Mono", size: 14) ?? .systemFont(ofSize: 14))
  }
}
