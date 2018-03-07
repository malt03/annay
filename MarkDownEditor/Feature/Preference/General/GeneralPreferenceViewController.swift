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
  @IBOutlet private weak var isHideEditorWhenUnfocusedCheckbox: NSButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    PreferenceManager.shared.general.map { $0.font.displayNameWithPoint }.distinctUntilChanged().bind(to: fontLabel.rx.text).disposed(by: bag)
    PreferenceManager.shared.general.map { $0.isHideEditorWhenUnfocused }.map { (isOn) -> NSControl.StateValue in
      return isOn ? .on : .off
    }.bind(to: isHideEditorWhenUnfocusedCheckbox.rx.state).disposed(by: bag)
    isHideEditorWhenUnfocusedCheckbox.rx.state.map { $0 == .on }.subscribe(onNext: { (isHideEditorWhenUnfocused) in
      PreferenceManager.shared.updateGeneral { (general) in general }
    }).disposed(by: bag)
  }

  @IBAction private func presentFontPanel(_ sender: NSButton) {
    FontManager.shared.showFontPanel()
  }
}
