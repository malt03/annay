//
//  NSAlert+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/29.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

extension NSAlert {
  convenience init(localizedMessageText: String) {
    self.init()
    messageText = Localized(localizedMessageText)
  }
}
