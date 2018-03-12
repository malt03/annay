//
//  ShortcutPreferenceNodeParameters.swift
//  Annay
//
//  Created by Koji Murata on 2018/03/12.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import Magnet

final class ShortcutPreferenceNodeParameters: Codable, ShortcutPreferenceParameters {
  var kind: Kind
  var keyCombo: KeyCombo?
  var node: CodableNode?
  
  enum Kind: String, Codable {
    case newNote
    case openNote
  }
  
  var kindRawValue: String { return kind.rawValue }
  
  init(kind: Kind) {
    self.kind = kind
    keyCombo = nil
    node = nil
  }
  
  func perform() {
    guard
      let workspace = node?.workspace,
      let node = node?.node
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
