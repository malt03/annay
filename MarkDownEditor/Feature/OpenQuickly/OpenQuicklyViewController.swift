//
//  OpenQuicklyViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/28.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class OpenQuicklyViewController: NSViewController {
  @IBOutlet weak var imageView: NSImageView!
  override func viewDidLoad() {
    super.viewDidLoad()
    imageView.image = #imageLiteral(resourceName: "Search").tinted(.text)
  }
    
}
