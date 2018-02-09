//
//  PreferenceTabViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/09.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class PreferenceTabViewController: NSTabViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // 何故かStrotyboardのローカライズが使えない
    tabViewItems[0].label = Localized("Shortcut")
  }
}
