//
//  Preference.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/03/06.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift
import Yams

protocol Preference: Codable {
  static var fileUrl: URL { get }
  init()
  var changed: Observable<Void> { get }
  func didCreated()
  func copy(from preference: Self)
}

extension Preference {
  func didCreated() {}
  
  private func prepare() {
    _ = changed.subscribe(onNext: { _ in self.save() })
  }

  func save() {
    let yaml = try! YAMLEncoder().encode(self)
    BookmarkManager.shared.getBookmarkedURL(Self.fileUrl, fallback: { Self.fileUrl }) { (bookmarkedURL) in
      try! yaml.write(to: bookmarkedURL, atomically: true, encoding: .utf8)
    }
  }
  
  func reload() {
    if let saved = (try? String(contentsOf: Self.fileUrl)).flatMap({ try? YAMLDecoder().decode(Self.self, from: $0) }) {
      copy(from: saved)
    }
  }
  
  static func create() -> Self {
    let preference: Self
    if let saved = (try? String(contentsOf: fileUrl)).flatMap({ try? YAMLDecoder().decode(Self.self, from: $0) }) {
      preference = saved
    } else {
      preference = Self.init()
    }
    preference.prepare()
    preference.didCreated()
    return preference
  }
}
