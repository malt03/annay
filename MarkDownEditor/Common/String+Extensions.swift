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
  
  func ranges(of string: String) -> [Range<String.Index>] {
    var ranges = [Range<String.Index>]()
    var searchStartIndex = self.startIndex
    
    while searchStartIndex < self.endIndex,
      let range = self.range(of: string, range: searchStartIndex..<self.endIndex),
      !range.isEmpty
    {
      ranges.append(range)
      searchStartIndex = range.upperBound
    }
    
    return ranges
  }
}
