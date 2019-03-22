//
//  MarkDownEditorError.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/29.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation

enum MarkDownEditorError: LocalizedError {
  case fileExists(oldUrl: URL?)
  case couldNotAccessFile(url: URL)
  
  var errorDescription: String? {
    switch self {
    case .fileExists:
      return Localized("File already exists.")
    case .couldNotAccessFile(url: let url):
      return Localized("Could not access file.") + "\n" + url.path
    }
  }
}
