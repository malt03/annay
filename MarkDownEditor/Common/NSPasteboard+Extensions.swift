//
//  NSPasteboard+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/15.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

extension NSPasteboard {
  var nodes: [NodeModel]? {
    guard let ids = string(forType: .nodeModel) else { return nil }
    return ids.split(separator: "\n").flatMap { NodeModel.node(for: String($0)) }
  }
}
