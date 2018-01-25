//
//  URL+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/26.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation

extension URL {
  var replacingHomePath: String {
    let homePath = FileManager.default.homeDirectoryForCurrentUser.path
    return path.replacingOccurrences(of: "^\(homePath)", with: "~", options: .regularExpression)
  }
}
