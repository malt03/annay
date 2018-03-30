//
//  Util.swift
//  Annay
//
//  Created by Koji Murata on 2018/03/28.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

func alertError(_ handler: () throws -> Void) {
  do {
    try handler()
  } catch {
    NSAlert(error: error).runModal()
  }
}
