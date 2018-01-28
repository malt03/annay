//
//  OpenQuicklyTextField.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/28.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class OpenQuicklyTextField: NSTextField {
  override func awakeFromNib() {
    super.awakeFromNib()
    focusRingType = .none
  }
}
