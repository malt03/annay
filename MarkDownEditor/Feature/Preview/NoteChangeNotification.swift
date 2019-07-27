//
//  NoteChangeNotification.swift
//  Annay
//
//  Created by Koji Murata on 2019/07/27.
//  Copyright © 2019 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift

struct NoteChangeNotification {
  static let subject = PublishSubject<NoteChangeNotification>()
  
  let sender: NSViewController
  let note: NodeModel?
}
