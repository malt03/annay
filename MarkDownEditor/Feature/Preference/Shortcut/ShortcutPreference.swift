//
//  ShortcutPreference.swift
//  Annay
//
//  Created by Koji Murata on 2018/03/11.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation
import RxSwift
import Magnet

final class ShortcutPreference: Preference {
  static let shared = ShortcutPreference.create()
  
  func copy(from preference: ShortcutPreference) {
    set(node: preference.newNote.node.value?.node, for: .newNote)
    set(keyCombo: preference.newNote.keyCombo.value, for: .newNote)
    set(node: preference.openNote.node.value?.node, for: .openNote)
    set(keyCombo: preference.openNote.keyCombo.value, for: .openNote)
  }
  
  func node(for kind: ShortcutPreferenceNodeParameters.Kind) -> CodableNode? {
    switch kind {
    case .newNote:  return newNote.node.value
    case .openNote: return openNote.node.value
    }
  }
  
  func keyCombo(for kind: ShortcutPreferenceNodeParameters.Kind) -> KeyCombo? {
    switch kind {
    case .newNote:  return newNote.keyCombo.value
    case .openNote: return openNote.keyCombo.value
    }
  }
  
  func set(node: NodeModel?, for kind: ShortcutPreferenceNodeParameters.Kind) {
    let codableNode: CodableNode?
    if let node = node {
      codableNode = CodableNode(node: node)
    } else {
      codableNode = nil
    }
    switch kind {
    case .newNote:  newNote.node.accept(codableNode)
    case .openNote: openNote.node.accept(codableNode)
    }
  }
  
  func set(keyCombo: KeyCombo?, for kind: ShortcutPreferenceNodeParameters.Kind) {
    switch kind {
    case .newNote:  newNote.keyCombo.accept(keyCombo)
    case .openNote: openNote.keyCombo.accept(keyCombo)
    }
  }

  var insertNode = PublishSubject<NodeModel>()
  
  func prepare() {
    for parameters in allParameters {
      parameters.prepare()
    }
  }
  
  static var fileUrl: URL { return PreferenceManager.shared.shortcutUrl }
  
  var changed: Observable<Void> {
    return Observable.combineLatest(newNote.changed, openNote.changed, resultSelector: { _, _ in }).skip(1)
  }
  
  private let newNote: ShortcutPreferenceNodeParameters
  private let openNote: ShortcutPreferenceNodeParameters
  
  private var allParameters: [ShortcutPreferenceNodeParameters] { return [newNote, openNote] }
  
  private enum CodingKeys: CodingKey {
    case newNote
    case openNote
  }
  
  init() {
    newNote = ShortcutPreferenceNodeParameters(kind: .newNote)
    openNote = ShortcutPreferenceNodeParameters(kind: .openNote)
  }
}
