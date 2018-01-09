//
//  TextView.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/09.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class TextView: NSTextView {
  override func awakeFromNib() {
    super.awakeFromNib()
    font = NSFont(name: "Osaka-Mono", size: 16)
  }
}
