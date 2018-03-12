//
//  GeneralPreference.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/03/06.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift

final class GeneralPreference: Preference {
  static let shared = GeneralPreference.create()
  
  static var fileUrl: URL { return PreferenceManager.shared.generalUrl }
  
  let isHideEditorWhenUnfocused: Variable<Bool>
  private var font: Variable<CodableFont>
  
  var changed: Observable<Void> {
    return Observable.combineLatest(isHideEditorWhenUnfocused.asObservable(), font.asObservable(), resultSelector: { (_, _) in })
  }

  var fontObservable: Observable<NSFont> { return font.asObservable().map { $0.font } }

  func convert(with manager: NSFontManager) {
    font.value = CodableFont(manager.convert(font.value.font))
  }
  
  func showFontPanel() {
    let fontPanel = NSFontPanel.shared
    fontPanel.setPanelFont(font.value.font, isMultiple: false)
    fontPanel.makeKeyAndOrderFront(nil)
  }
  
  init() {
    self.isHideEditorWhenUnfocused = Variable(false)
    self.font = Variable(CodableFont(NSFont(name: "Osaka-Mono", size: 14) ?? .systemFont(ofSize: 14)))
  }
}
