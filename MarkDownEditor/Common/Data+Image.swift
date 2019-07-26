//
//  Data+Image.swift
//  Annay
//
//  Created by Koji Murata on 2019/07/27.
//  Copyright © 2019 Koji Murata. All rights reserved.
//

import Foundation

fileprivate enum ImageFormat: UInt8 {
  case unknown = 0x00
  case png = 0x89
  case jpeg = 0xFF
  case gif = 0x47
  case tiff1 = 0x49
  case tiff2 = 0x4D
  
  private var text: String {
    switch self {
    case .unknown:       return "unknown"
    case .png:           return "png"
    case .jpeg:          return "jpeg"
    case .gif:           return "gif"
    case .tiff1, .tiff2: return "tiff"
    }
  }
  
  var base64Header: String {
    return "data:image/\(text);base64,"
  }
}

extension Data {
  private var imageFormat: ImageFormat {
    return ImageFormat(rawValue: self[0]) ?? .unknown
  }
  
  var imageTagBase64EncodedSrc: String {
    return imageFormat.base64Header + base64EncodedString()
  }
}
