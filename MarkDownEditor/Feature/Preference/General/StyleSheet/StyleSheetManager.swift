//
//  StyleSheetManager.swift
//  Annay
//
//  Created by Koji Murata on 2018/03/13.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation
import RxSwift

final class StyleSheetManager {
  private let bag = DisposeBag()
  static let shared = StyleSheetManager()
  
  let all: Variable<[StyleSheet]>
  let selected = Variable<StyleSheet?>(nil)
  private let fileWatcher = StyleSheetFileWatcher()
  
  static func createDefaultCss() {
    do {
      let bundleCss = Bundle.main.url(forResource: "swiss", withExtension: "css")!
      try FileManager.default.copyItem(at: bundleCss, to: defaultCss)
    } catch {}
  }
  
  private static func createDefaultCssIfNeeded() {
    if !FileManager.default.fileExists(atPath: defaultCss.path) {
      createDefaultCss()
    }
  }
  
  private static var directoryUrl: URL { return PreferenceManager.shared.styleSheetsUrl }
  private static var defaultCss: URL { return directoryUrl.appendingPathComponent("default.css") }
  
  private init() {
    do {
      let fileManager = FileManager.default
      try fileManager.createDirectoryIfNeeded(url: StyleSheetManager.directoryUrl)
      StyleSheetManager.createDefaultCssIfNeeded()

      let files = try fileManager.contentsOfDirectory(at: StyleSheetManager.directoryUrl, includingPropertiesForKeys: [], options: [])
      let styleSheets = files.compactMap { StyleSheet(file: $0) }
      all = Variable(styleSheets)
    } catch {
      all = Variable([])
    }
  
    GeneralPreference.shared.styleSheetName.asObservable().map({ [weak self] (name) -> StyleSheet? in
      guard let s = self, let name = name else { return nil }
      return s.all.value.first(where: { $0.name == name })
    }).bind(to: selected).disposed(by: bag)
    
    fileWatcher.fileAdded.subscribe(onNext: { [weak self] (url) in
      guard let s = self, let styleSheet = StyleSheet(file: url) else { return }
      s.all.value.append(styleSheet)
      if s.selected.value == nil { styleSheet.select() }
    }).disposed(by: bag)
    fileWatcher.fileDeleted.subscribe(onNext: { [weak self] (url) in
      guard let s = self, let index = s.all.value.index(where: { $0.fileUrl == url }) else { return }
      s.all.value.remove(at: index)
    }).disposed(by: bag)
  }
}
