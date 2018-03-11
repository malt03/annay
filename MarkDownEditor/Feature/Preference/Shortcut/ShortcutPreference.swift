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
  
  func parameters(for kind: Kind) -> Observable<ShortcutPreferenceParameters?> {
    return shortcuts.asObservable().map { $0[kind] }
  }
  
  func set(for kind: Kind, parameters: ShortcutPreferenceParameters) {
    shortcuts.value[kind] = parameters
  }
  
  enum Kind: String, Codable {
    case new
    case open
  }

  static var fileUrl: URL { return PreferenceManager.shared.shortcutUrl }
  
  var changed: Observable<Void> {
    return shortcuts.asObservable().void
  }
  
  private var shortcuts: Variable<[Kind: ShortcutPreferenceParameters]>
  
  init() {
    shortcuts = Variable([:])
  }
}
