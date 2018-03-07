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
    GeneralPreference.shared.font.asObservable().map { $0.displayNameWithPoint }.distinctUntilChanged().bind(to: fontLabel.rx.text).disposed(by: bag)
    GeneralPreference.shared.isHideEditorWhenUnfocused.asObservable().map { (isOn) -> NSControl.StateValue in
      return isOn ? .on : .off
    }.bind(to: isHideEditorWhenUnfocusedCheckbox.rx.state).disposed(by: bag)
    isHideEditorWhenUnfocusedCheckbox.rx.state.map { $0 == .on }.bind(to: GeneralPreference.shared.isHideEditorWhenUnfocused).disposed(by: bag)
  }

  @IBAction private func presentFontPanel(_ sender: NSButton) {
    GeneralPreference.shared.showFontPanel()
  }
}
