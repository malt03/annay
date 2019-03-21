//
//  StyleSheetManager.swift
//  Annay
//
//  Created by Koji Murata on 2018/03/13.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift

final class StyleSheetManager {
  private let bag = DisposeBag()
  static let shared = StyleSheetManager()
  
  let all: Variable<[StyleSheet]>
  let selected: Variable<StyleSheet>
  private let fileWatcher = StyleSheetFileWatcher()
  
  static func createDefaultCsses(force: Bool) {
    for url in [darkCss, lightCss] {
      if FileManager.default.fileExists(atPath: url.path) {
        if !force { continue }
        try! FileManager.default.removeItem(at: url)
      }
      let bundleCss = Bundle.main.url(forResource: url.lastPathComponent, withExtension: nil)!
      try! FileManager.default.copyItem(at: bundleCss, to: url)
    }
  }
  
  static var directoryUrl: URL { return PreferenceManager.shared.styleSheetsUrl }
  private static var darkCss: URL { return directoryUrl.appendingPathComponent("dark.css") }
  private static var lightCss: URL { return directoryUrl.appendingPathComponent("light.css") }
  
  private init() {
    let fileManager = FileManager.default
    try! fileManager.createDirectoryIfNeeded(url: StyleSheetManager.directoryUrl)
    StyleSheetManager.createDefaultCsses(force: false)
    
    let files = try! fileManager.contentsOfDirectory(at: StyleSheetManager.directoryUrl, includingPropertiesForKeys: [], options: [])
    let styleSheets = files.compactMap { StyleSheet(file: $0) }
    all = Variable(styleSheets)

    if NSAppearance.effective.isDark {
      selected = Variable<StyleSheet>(StyleSheet(file: StyleSheetManager.darkCss)!)
    } else {
      selected = Variable<StyleSheet>(StyleSheet(file: StyleSheetManager.lightCss)!)
    }
  
    GeneralPreference.shared.styleSheetName.asObservable().map({ [weak self] (name) -> StyleSheet? in
      guard let s = self else { return nil }
      return s.all.value.first(where: { $0.name == name })
    }).filter { $0 != nil }.map { $0! }.bind(to: selected).disposed(by: bag)
    
    fileWatcher.fileAddedOrChanged.subscribe(onNext: { [weak self] (url) in
      guard let s = self, let styleSheet = StyleSheet(file: url) else { return }
      for i in 0..<s.all.value.count {
        if s.all.value[i].fileUrl == url {
          s.all.value[i].reload()
          if s.all.value[i].fileUrl == s.selected.value.fileUrl {
            s.selected.value.reload()
          }
          return
        }
      }
      s.all.value.append(styleSheet)
    }).disposed(by: bag)
    fileWatcher.fileDeleted.subscribe(onNext: { [weak self] (url) in
      guard let s = self, let index = s.all.value.index(where: { $0.fileUrl == url }) else { return }
      s.all.value.remove(at: index)
    }).disposed(by: bag)
  }
}
