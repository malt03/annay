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
  
  func node(for kind: ShortcutPreferenceNodeParameters.Kind) -> CodableNode? {
    switch kind {
    case .newNote:  return newNote.value.node
    case .openNote: return openNote.value.node
    }
  }
  
  func keyCombo(for kind: ShortcutPreferenceNodeParameters.Kind) -> KeyCombo? {
    switch kind {
    case .newNote:  return newNote.value.keyCombo
    case .openNote: return openNote.value.keyCombo
    }
  }
  
  func set(node: NodeModel?, workspace: WorkspaceModel?, for kind: ShortcutPreferenceNodeParameters.Kind) {
    let codableNode: CodableNode?
    if let node = node, let workspace = workspace {
      codableNode = CodableNode(node: node, workspace: workspace)
    } else {
      codableNode = nil
    }
    switch kind {
    case .newNote:  newNote.value.node = codableNode
    case .openNote: openNote.value.node = codableNode
    }
  }
  
  func set(keyCombo: KeyCombo?, for kind: ShortcutPreferenceNodeParameters.Kind) {
    switch kind {
    case .newNote:  newNote.value.keyCombo = keyCombo
    case .openNote: openNote.value.keyCombo = keyCombo
    }
  }

  var insertNode = PublishSubject<NodeModel>()
  
  func prepare() {
    for parameters in allParameters {
      parameters.register()
    }
  }
  
  static var fileUrl: URL { return PreferenceManager.shared.shortcutUrl }
  
  var changed: Observable<Void> {
    return Observable.combineLatest(newNote.asObservable(), openNote.asObservable(), resultSelector: { _, _ in })
  }
  
  let newNote: Variable<ShortcutPreferenceNodeParameters>
  let openNote: Variable<ShortcutPreferenceNodeParameters>
  
  private var allParameters: [ShortcutPreferenceParameters] { return [newNote.value, openNote.value] }
  
  private enum CodingKeys: CodingKey {
    case newNote
    case openNote
  }
  
  init() {
    newNote = Variable(ShortcutPreferenceNodeParameters(kind: .newNote))
    openNote = Variable(ShortcutPreferenceNodeParameters(kind: .openNote))
  }
}
