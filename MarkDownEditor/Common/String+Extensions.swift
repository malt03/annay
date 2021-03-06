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
  
  func match(with pattern: String) -> Substring? {
    guard let oldRange = oldRanges(with: pattern).first else { return nil }
    return self[range(from: oldRange)]
  }
  
  func oldRanges(with pattern: String) -> [NSRange] {
    let regex = try! NSRegularExpression(pattern: pattern, options: [])
    let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: count))
    return matches.map { $0.range }
  }
  
  func range(from old: NSRange) -> Range<String.Index> {
    let start = index(startIndex, offsetBy: old.location)
    let end = index(start, offsetBy: old.length)
    return start..<end
  }
  
  func oldRange(from range: Range<String.Index>) -> NSRange {
    return NSRange(location: distance(from: startIndex, to: range.lowerBound), length: distance(from: range.lowerBound, to: range.upperBound))
  }
  
  func oldRange(from range: ClosedRange<String.Index>) -> NSRange {
    return NSRange(location: distance(from: startIndex, to: range.lowerBound), length: distance(from: range.lowerBound, to: range.upperBound))
  }
  
  var replacingHomePathToTilde: String {
    return replacingOccurrences(of: "^\(getHomeDirectoryPath())", with: "~", options: .regularExpression)
  }
  
  var replacingTildeToHomePath: String {
    return replacingOccurrences(of: "^~", with: getHomeDirectoryPath(), options: .regularExpression)
  }
  
  private func getHomeDirectoryPath() -> String {
    guard
      let pw = getpwuid(getuid()),
      let home = pw.pointee.pw_dir
      else { return "" }
    return FileManager.default.string(withFileSystemRepresentation: home, length: Int(strlen(home)))
  }
}
