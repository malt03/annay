//
//  WorkspaceNameFormatter.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/29.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class WorkspaceNameFormatter: Formatter {
  @IBInspectable var allowEmpty: Bool = false
  
  override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
    obj?.pointee = string as AnyObject
    return true
  }
  
  override func string(for obj: Any?) -> String? {
    return obj as? String
  }
  
  override func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
    if partialString.contains("/") {
      NSAlert(localizedMessageText: "Invalid character.").runModal()
      return false
    }
    if partialString.count >= 64 {
      NSAlert(localizedMessageText: "Workspace name is too long.").runModal()
      return false
    }
    if !allowEmpty && partialString.count == 0 {
      NSAlert(localizedMessageText: "Workspace name cannot be blank.").runModal()
      return false
    }
    return true
  }
}
