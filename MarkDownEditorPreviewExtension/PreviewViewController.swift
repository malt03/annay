//
//  PreviewViewController.swift
//  MarkDownEditorPreviewExtension
//
//  Created by Koji Murata on 2018/02/20.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import Quartz

class PreviewViewController: NSViewController, QLPreviewingController {
  
  override var nibName: NSNib.Name? {
    return NSNib.Name("PreviewViewController")
  }
  
  @IBOutlet weak var label: NSTextField!
  
  func preparePreviewOfSearchableItem(withIdentifier identifier: String, queryString: String, completionHandler handler: @escaping QLPreviewItemLoadingBlock) {
    print(SpotlightDataStore.shared.body(for: identifier))
    
    handler(nil)
  }
  
}
