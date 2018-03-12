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
}

extension Preference {
  private func prepare() {
    _ = changed.subscribe(onNext: { _ in self.save() })
  }

  func save() {
    do {
      let yaml = try YAMLEncoder().encode(self)
      try yaml.write(to: Self.fileUrl, atomically: true, encoding: .utf8)
    } catch {
      NSAlert(error: error).runModal()
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
    return preference
  }
}
