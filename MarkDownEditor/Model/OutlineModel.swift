//
//  OutlineModel.swift
//  Annay
//
//  Created by Koji Murata on 2019/03/27.
//  Copyright © 2019 Koji Murata. All rights reserved.
//

import Foundation
import RxSwift

final class OutlineModel {
  static let selected = PublishSubject<OutlineModel>()
  
  let title: String
  let range: NSRange
  private(set) var children: [OutlineModel]? = nil
  
  init(title: String, range: NSRange) {
    self.title = title
    self.range = range
  }
  
  private static let regex = try! NSRegularExpression(pattern: "^#+ .+$", options: [.anchorsMatchLines])
  private static let headerRegex = try! NSRegularExpression(pattern: "^#+", options: [])
  
  private struct AbstractOutlineModel {
    let title: String
    let range: NSRange
    let sharpCount: Int
  }
  
  static func create(from text: String) -> ([OutlineModel], [String: OutlineModel]) {
    var abstracts = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count)).map { (result) -> AbstractOutlineModel in
      let range = Range(result.range, in: text)!
      let title = String(text[range])
      let headerResult = headerRegex.firstMatch(in: title, options: [], range: NSRange(location: 0, length: title.count))!
      let headerRange = Range(headerResult.range, in: text)!
      let sharpCount = title[headerRange].count
      return AbstractOutlineModel(title: title, range: result.range, sharpCount: sharpCount)
    }
    return create(with: &abstracts)
  }
  
  static private func create(with abstracts: inout [AbstractOutlineModel]) -> ([OutlineModel], [String: OutlineModel]) {
    if abstracts.count == 0 { return ([], [:]) }
    let sharpCount = abstracts[0].sharpCount
    var outlines = [OutlineModel]()
    var outlineDictionary = [String: OutlineModel]()
    while abstracts.count > 0 {
      let current = abstracts[0]
      if current.sharpCount < sharpCount {
        return (outlines, outlineDictionary)
      } else if current.sharpCount > sharpCount {
        let (createdOutlines, createdOutlineDictionary) = create(with: &abstracts)
        if let exists = outlines[outlines.count - 1].children {
          outlines[outlines.count - 1].children = exists + createdOutlines
        } else {
          outlines[outlines.count - 1].children = createdOutlines
        }
        outlineDictionary.merge(createdOutlineDictionary, uniquingKeysWith: { (a, _) in a })
      } else {
        let outline = OutlineModel(title: current.title, range: current.range)
        outlineDictionary[outline.title] = outline
        outlines.append(outline)
        abstracts.remove(at: 0)
      }
    }
    return (outlines, outlineDictionary)
  }
}

extension OutlineModel: Equatable {
  static func == (lhs: OutlineModel, rhs: OutlineModel) -> Bool {
    return lhs.title == rhs.title
  }
}
