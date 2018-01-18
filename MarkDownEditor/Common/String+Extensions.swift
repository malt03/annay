//
//  String+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/18.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation

extension String {
  var firstCharacterString: String? {
    guard let character = first else { return nil }
    return String(character)
  }
}
