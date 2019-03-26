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
  @IBOutlet private weak var styleSheetPopupButton: NSPopUpButton!
  @IBOutlet private weak var preferenceDirectoryTextField: NSTextField!
  
  @IBAction private func changePreferenceDirectory(_ sender: NSButton) {
    guard let window = view.window else { return }
    let openPanel = NSOpenPanel()
    openPanel.allowsMultipleSelection = false
    openPanel.canChooseDirectories = true
    openPanel.canCreateDirectories = true
    openPanel.canChooseFiles = false
    openPanel.beginSheetModal(for: window) { (result) in
      if result != .OK { return }
      guard let url = openPanel.url else { return }
      PreferenceManager.shared.directoryUrl.value = url
      BookmarkManager.shared.bookmark(url: url)
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    GeneralPreference.shared.fontObservable.asObservable().map { $0.displayNameWithPoint }.distinctUntilChanged().bind(to: fontLabel.rx.text).disposed(by: bag)
    GeneralPreference.shared.isHideEditorWhenUnfocused.asObservable().map { (isOn) -> NSControl.StateValue in
      return isOn ? .on : .off
    }.bind(to: isHideEditorWhenUnfocusedCheckbox.rx.state).disposed(by: bag)
    isHideEditorWhenUnfocusedCheckbox.rx.state.map { $0 == .on }.bind(to: GeneralPreference.shared.isHideEditorWhenUnfocused).disposed(by: bag)

    StyleSheetManager.shared.all.asObservable().subscribe(onNext: { [weak self] (styleSheets) in
      guard let s = self else { return }
      s.styleSheetPopupButton.removeAllItems()
      s.styleSheetPopupButton.addItems(withTitles: styleSheets.map { $0.name })
    }).disposed(by: bag)
    
    StyleSheetManager.shared.selected.asObservable().subscribe(onNext: { [weak self] (styleSheet) in
      guard let s = self else { return }
      s.styleSheetPopupButton.selectItem(withTitle: styleSheet.name)
    }).disposed(by: bag)
    
    styleSheetPopupButton.rx.controlEvent.subscribe(onNext: { [weak self] _ in
      guard let s = self else { return }
      StyleSheetManager.shared.all.value[s.styleSheetPopupButton.indexOfSelectedItem].select()
    }).disposed(by: bag)
    
    PreferenceManager.shared.directoryUrl.asObservable().map { $0.path.replacingHomePathToTilde }.bind(to: preferenceDirectoryTextField.rx.text).disposed(by: bag)
  }

  @IBAction private func openDirecotry(_ sender: NSButton) {
    let url = StyleSheetManager.directoryUrl
    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
  }
  
  @IBAction private func presentFontPanel(_ sender: NSButton) {
    GeneralPreference.shared.showFontPanel()
  }
  @IBAction private func resetDefaultStyleSheet(_ sender: NSButton) {
    let alert = NSAlert()
    alert.messageText = Localized("This operation cannot be undone.")
    alert.addButton(withTitle: Localized("Cancel"))
    alert.addButton(withTitle: Localized("Reset"))
    let response = alert.runModal()
    if response == .alertSecondButtonReturn {
      StyleSheetManager.createDefaultCsses(force: true)
    }
  }
}
