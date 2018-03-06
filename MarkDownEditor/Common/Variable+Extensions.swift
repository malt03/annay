//
//  Variable+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/03/06.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation
import RxSwift

extension Variable: Codable where Element: Codable {
  public convenience init(from decoder: Decoder) throws {
    self.init(try decoder.singleValueContainer().decode(Element.self))
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(value)
  }
} 
