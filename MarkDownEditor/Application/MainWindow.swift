//
//  MainWindow.swift
//  Annay
//
//  Created by Koji Murata on 2018/04/10.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift

final class MainWindow: NSWindow {
  private lazy var firstResponderSubject = BehaviorSubject(value: firstResponder)
  var firstResponderObservable: Observable<NSResponder?> { return firstResponderSubject }
  override func makeFirstResponder(_ responder: NSResponder?) -> Bool {
    let should = super.makeFirstResponder(responder)
    firstResponderSubject.onNext(firstResponder)
    return should
  }
}
