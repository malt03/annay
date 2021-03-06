//
//  ShortcutPreferenceNodeParameters.swift
//  Annay
//
//  Created by Koji Murata on 2018/03/12.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import Magnet
import RxSwift
import RxRelay

// NSObjectを継承しないと、ショートカットキーが何故か機能しない
final class ShortcutPreferenceNodeParameters: NSObject, Codable {
  private let bag = DisposeBag()
  
  var kind: Kind
  var keyCombo: BehaviorRelay<KeyCombo?>
  var node: BehaviorRelay<CodableNode?>
  
  var changed: Observable<Void> {
    return Observable.combineLatest(keyCombo.asObservable(), node.asObservable(), resultSelector: { _, _ in })
  }
  
  private enum CodingKeys: CodingKey {
    case kind
    case keyCombo
    case node
  }
  
  enum Kind: String, Codable {
    case newNote
    case openNote
  }
  
  init(kind: Kind) {
    self.kind = kind
    keyCombo = BehaviorRelay(value: nil)
    node = BehaviorRelay(value: nil)
  }
  
  func prepare() {
    keyCombo.asObservable().subscribe(onNext: { [weak self] (keyCombo) in
      guard let s = self else { return }
      HotKeyCenter.shared.unregisterHotKey(with: s.kind.rawValue)
      guard let keyCombo = keyCombo else { return }
      let hotKey = HotKey(identifier: s.kind.rawValue, keyCombo: keyCombo, target: s, action: #selector(s.performHotKey))
      hotKey.register()
    }).disposed(by: bag)
  }
  
  @objc private func performHotKey() {
    guard
      let workspace = node.value?.node?.workspace,
      let node = node.value?.node
      else {
        NSAlert(localizedMessageText: "No parent directory was selected.").runModal()
        return
      }
    workspace.select()

    let note: NodeModel
    switch kind {
    case .newNote:
      note = NodeModel.createNote(in: node)
      ShortcutPreference.shared.insertNode.onNext(note)
    case .openNote: note = node
    }
    note.select()

    NotificationCenter.default.post(name: .MoveFocusToEditor, object: nil)
    Application.shared.activate(ignoringOtherApps: true)
  }
}
