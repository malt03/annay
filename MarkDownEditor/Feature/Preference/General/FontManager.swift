//
//  FontManager.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/10.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift

final class FontManager {
  static let shared = FontManager()
  
  private let _font: Variable<NSFont>
  var font: Observable<NSFont> { return _font.asObservable() }
  
  private struct Key {
    static let SavedFontName = "FontManager/SavedFontName"
    static let SavedFontSize = "FontManager/SavedFontSize"
  }
  
  private static var savedFont: NSFont? {
    get {
      let ud = UserDefaults.standard
      guard
        let name = ud.string(forKey: Key.SavedFontName),
        let size = ud.object(forKey: Key.SavedFontSize) as? CGFloat
        else { return nil }
      return NSFont(name: name, size: size)
    }
    set {
      let ud = UserDefaults.standard
      ud.set(newValue?.fontName, forKey: Key.SavedFontName)
      ud.set(newValue?.pointSize, forKey: Key.SavedFontSize)
      ud.synchronize()
    }
  }
  
  private static var defaultFont: NSFont { return NSFont(name: "Osaka-Mono", size: 14) ?? .systemFont(ofSize: 14) }
  
  private init() {
    _font = Variable<NSFont>(FontManager.savedFont ?? FontManager.defaultFont)
  }
  
  func convert(with manager: NSFontManager) {
    let newFont = manager.convert(_font.value)
    FontManager.savedFont = newFont
    _font.value = newFont
  }
  
  func showFontPanel() {
    let fontPanel = NSFontPanel.shared
    fontPanel.setPanelFont(_font.value, isMultiple: false)
    fontPanel.makeKeyAndOrderFront(nil)
  }
}
