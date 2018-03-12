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

final class ShortcutPreferenceNodeParameters: Codable {
  private let bag = DisposeBag()
  
  var kind: Kind
  var keyCombo: Variable<KeyCombo?>
  var node: Variable<CodableNode?>
  
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
    keyCombo = Variable(nil)
    node = Variable(nil)
  }
  
  func prepare() {
    keyCombo.asObservable().subscribe(onNext: { [weak self] (keyCombo) in
      guard let s = self else { return }
      HotKeyCenter.shared.unregisterHotKey(with: s.kind.rawValue)
      guard let keyCombo = keyCombo else { return }
      HotKey(identifier: s.kind.rawValue, keyCombo: keyCombo, target: self as AnyObject, action: #selector(s.perform)).register()
    }).disposed(by: bag)
  }
  
  @objc func perform() {
    guard
      let workspace = node.value?.workspace,
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
    note.selected()

    NotificationCenter.default.post(name: .MoveFocusToEditor, object: nil)
    Application.shared.activate(ignoringOtherApps: true)
  }
}

extension KeyCombo: Codable {
  private enum CodingKeys: CodingKey {
    case keyCode
    case modifiers
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(keyCode, forKey: .keyCode)
    try container.encode(modifiers, forKey: .modifiers)
  }
  
  public convenience init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let keyCode = try container.decode(Int.self, forKey: .keyCode)
    let modifiers = try container.decode(Int.self, forKey: .modifiers)
    self.init(keyCode: keyCode, carbonModifiers: modifiers)!
  }
}
