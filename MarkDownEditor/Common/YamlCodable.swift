//
//  YamlCodable.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/03/07.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import Yams

protocol YamlCodable: Codable {
  static var fileUrl: URL { get }
  init()
}

extension YamlCodable {
  func save() {
    do {
      let yaml = try YAMLEncoder().encode(self)
      try yaml.write(to: Self.fileUrl, atomically: true, encoding: .utf8)
    } catch {
      NSAlert(error: error).runModal()
    }
  }
  
  static func create() -> Self {
    if let saved = (try? String(contentsOf: fileUrl)).flatMap({ try? YAMLDecoder().decode(Self.self, from: $0) }) {
      return saved
    }
    return Self.init()
  }
}
