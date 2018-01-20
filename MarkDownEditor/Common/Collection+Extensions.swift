//
//  Collection+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/20.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation
import RealmSwift

extension Collection {
  subscript(safe index: Index) -> Element? {
    return index >= startIndex && index < endIndex ? self[index] : nil
  }
}

extension Results {
  subscript(safe index: Index) -> Element? {
    return index >= startIndex && index < endIndex ? self[index] : nil
  }
}

