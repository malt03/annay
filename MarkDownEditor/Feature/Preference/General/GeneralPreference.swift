//
//  GeneralPreference.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/03/06.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift
import Yams

final class GeneralPreference: YamlCodable {
  static let shared = GeneralPreference.create()
  
  static var fileUrl: URL { return PreferenceManager.shared.generalUrl }
  
  let isHideEditorWhenUnfocused: Variable<Bool>
  private var _font: Variable<CodableFont>

  var font: Observable<NSFont> { return _font.asObservable().map { $0.font } }

  func convert(with manager: NSFontManager) {
    _font.value = CodableFont(manager.convert(_font.value.font))
  }
  
  func showFontPanel() {
    let fontPanel = NSFontPanel.shared
    fontPanel.setPanelFont(_font.value.font, isMultiple: false)
    fontPanel.makeKeyAndOrderFront(nil)
  }
  
  init() {
    self.isHideEditorWhenUnfocused = Variable(false)
    self._font = Variable(CodableFont(NSFont(name: "Osaka-Mono", size: 14) ?? .systemFont(ofSize: 14)))
  }
}
