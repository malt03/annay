//
//  Preference.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/03/06.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import Yams

struct Preference: Codable {
  let general: GeneralPreference
  
  private init() {
    general = .default
  }
  
  init(from yaml: URL) {
    self = (try? String(contentsOf: yaml)).flatMap({ try? YAMLDecoder().decode(Preference.self, from: $0) }) ?? Preference()
  }
  
  func save(to yaml: URL) {
    do {
      let yamlString = try YAMLEncoder().encode(self)
      try yamlString.write(to: yaml, atomically: true, encoding: .utf8)
    } catch {
      NSAlert(error: error).runModal()
    }
  }
}
