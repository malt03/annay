//
//  DateFormatter+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/03.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation

extension DateFormatter {
  convenience init(dateStyle: Style, timeStyle: Style) {
    self.init()
    self.dateStyle = dateStyle
    self.timeStyle = timeStyle
  }
}
