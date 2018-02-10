//
//  GeneralPreferenceViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/10.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift

final class GeneralPreferenceViewController: NSViewController {
  private let bag = DisposeBag()
  
  @IBOutlet private weak var fontLabel: NSTextField!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    FontManager.shared.font.map { $0.displayNameWithPoint }.bind(to: fontLabel.rx.text).disposed(by: bag)
  }

  @IBAction private func presentFontPanel(_ sender: NSButton) {
    FontManager.shared.showFontPanel()
  }
}
