//
//  StyleSheetManager.swift
//  Annay
//
//  Created by Koji Murata on 2018/03/13.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift
import RxRelay

final class StyleSheetManager {
  private let bag = DisposeBag()
  static let shared = StyleSheetManager()
  
  let all: BehaviorRelay<[StyleSheet]>
  let selected: BehaviorRelay<StyleSheet>
  private let fileWatcher = StyleSheetFileWatcher()
  
  static func createDefaultCsses(force: Bool) {
    for url in [darkCss, lightCss] {
      BookmarkManager.shared.getBookmarkedURL(url, fallback: { url }) { (url) in
        if FileManager.default.fileExists(atPath: url.path) {
          if !force { return }
          try! FileManager.default.removeItem(at: url)
        }
        let bundleCss = Bundle.main.url(forResource: url.lastPathComponent, withExtension: nil)!
        try! FileManager.default.copyItem(at: bundleCss, to: url)
      }
    }
  }
  
  static var directoryUrl: URL { return PreferenceManager.shared.styleSheetsUrl }
  private static var darkCss: URL { return directoryUrl.appendingPathComponent("dark.css") }
  private static var lightCss: URL { return directoryUrl.appendingPathComponent("light.css") }
  
  private init() {
    let fileManager = FileManager.default
    var all = [StyleSheet]()
    
    BookmarkManager.shared.getBookmarkedURL(StyleSheetManager.directoryUrl, fallback: { () -> URL in
      PreferenceManager.shared.resetDirectory()
      return StyleSheetManager.directoryUrl
    }) { (bookmarkedDirectoryURL) in
      try! fileManager.createDirectoryIfNeeded(url: bookmarkedDirectoryURL)
      StyleSheetManager.createDefaultCsses(force: false)
      let files = try! fileManager.contentsOfDirectory(at: bookmarkedDirectoryURL, includingPropertiesForKeys: [], options: [])
      let styleSheets = files.compactMap { StyleSheet(file: $0) }
      all = styleSheets
    }
    self.all = BehaviorRelay(value: all)

    if NSAppearance.effective.isDark {
      selected = BehaviorRelay(value: StyleSheet(file: StyleSheetManager.darkCss)!)
    } else {
      selected = BehaviorRelay(value: StyleSheet(file: StyleSheetManager.lightCss)!)
    }
  
    GeneralPreference.shared.styleSheetName.asObservable().map({ [weak self] (name) -> StyleSheet? in
      guard let s = self else { return nil }
      return s.all.value.first(where: { $0.name == name })
    }).filter { $0 != nil }.map { $0! }.bind(to: selected).disposed(by: bag)
    
    fileWatcher.fileAddedOrChanged.subscribe(onNext: { [weak self] (url) in
      guard let s = self, let styleSheet = StyleSheet(file: url) else { return }
      for i in 0..<s.all.value.count {
        if s.all.value[i].fileUrl == url {
          s.all.mutate { (old) -> [StyleSheet] in
            var new = old
            new[i].reload()
            return new
          }
          if s.all.value[i].fileUrl == s.selected.value.fileUrl {
            s.selected.mutate { (old) -> StyleSheet in
              var new = old
              new.reload()
              return new
            }
          }
          return
        }
      }
      var allValue = s.all.value
      allValue.append(styleSheet)
      s.all.accept(allValue)
    }).disposed(by: bag)
    fileWatcher.fileDeleted.subscribe(onNext: { [weak self] (url) in
      guard let s = self, let index = s.all.value.firstIndex(where: { $0.fileUrl == url }) else { return }
      s.all.mutate { (old) -> [StyleSheet] in
        var new = old
        new.remove(at: index)
        return new
      }
    }).disposed(by: bag)
  }
}
