//
//  OpenQuicklyNodeTableCellView.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/28.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class OpenQuicklyNodeTableCellView: NSTableCellView {
  @IBOutlet private weak var nodeNameLabel: NSTextField!
  @IBOutlet private weak var pathLabel: NSTextField!
  @IBOutlet private weak var workspaceLabel: NSTextField!
  
  func prepare(node: NodeModel) {
    nodeNameLabel.stringValue = node.name
    pathLabel.stringValue = node.path
    workspaceLabel.stringValue = node.workspace?.nameValue ?? ""
  }
}
