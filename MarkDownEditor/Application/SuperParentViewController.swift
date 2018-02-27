//
//  SuperParentViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/27.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift

final class SuperParentViewController: NSViewController {
  private let bag = DisposeBag()
  
  @IBOutlet private weak var overlayView: NSView!
  @IBOutlet private weak var indicator: NSProgressIndicator!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    (NSApplication.shared as! Application).isEnabled.asObservable().subscribe(onNext: { [weak self] (isEnabled) in
      guard let s = self else { return }
      s.overlayView.isHidden = isEnabled
      if isEnabled {
        s.indicator.stopAnimation(nil)
      } else {
        s.indicator.startAnimation(nil)
      }
    }).disposed(by: bag)
  }
}
