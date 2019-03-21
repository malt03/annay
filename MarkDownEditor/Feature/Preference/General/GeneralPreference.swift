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
  let styleSheetName: Variable<String>
  
  func didCreated() {
    checkAppearance()
  }
  

  func copy(from preference: GeneralPreference) {
    isHideEditorWhenUnfocused.value = preference.isHideEditorWhenUnfocused.value
    font.value = preference.font.value
    styleSheetName.value = preference.styleSheetName.value
  }

  func checkAppearance() {
    if NSAppearance.effective.isDark {
      if styleSheetName.value == GeneralPreference.lightStyle {
        styleSheetName.value = GeneralPreference.darkStyle
      }
    } else {
      if styleSheetName.value == GeneralPreference.darkStyle {
        styleSheetName.value = GeneralPreference.lightStyle
      }
    }
  }

  var changed: Observable<Void> {
    return Observable.combineLatest(
      isHideEditorWhenUnfocused.asObservable(),
      font.asObservable(),
      styleSheetName.asObservable(),
      resultSelector: { (_, _, _) in }
    )
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
  
  static var darkStyle: String { return "dark.css" }
  static var lightStyle: String { return "light.css" }
  
  init() {
    self.isHideEditorWhenUnfocused = Variable(false)
    self.font = Variable(CodableFont(NSFont(name: "Osaka-Mono", size: 14) ?? .systemFont(ofSize: 14)))
    self.styleSheetName = Variable(NSAppearance.effective.isDark ? GeneralPreference.darkStyle : GeneralPreference.lightStyle)
  }
}
