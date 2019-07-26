//
//  BehaviorRelay+Extension.swift
//  Annay
//
//  Created by Koji Murata on 2019/07/26.
//  Copyright © 2019 Koji Murata. All rights reserved.
//

import Foundation
import RxRelay

extension BehaviorRelay: Codable where Element: Codable {
  public convenience init(from decoder: Decoder) throws {
    self.init(value: try decoder.singleValueContainer().decode(Element.self))
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(value)
  }
}

extension BehaviorRelay {
  func mutate(_ handler: (Element) -> Element) {
    accept(handler(value))
  }
}
