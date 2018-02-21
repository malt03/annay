//
//  GeneralPreferenceManager.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/22.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation
import RxSwift

final class GeneralPreferenceManager {
  private struct Key {
    static let IsHideEditorWhenUnfocused = "GeneralPreferenceManager/IsHideEditorWhenUnfocused"
  }
  
  static let shared = GeneralPreferenceManager()
  
  var isHideEditorWhenUnfocused: Variable<Bool>
  
  private init() {
    let isHideEditorWhenUnfocused = UserDefaults.standard.bool(forKey: Key.IsHideEditorWhenUnfocused)
    self.isHideEditorWhenUnfocused = Variable<Bool>(isHideEditorWhenUnfocused)
    
    _ = self.isHideEditorWhenUnfocused.asObservable().subscribe(onNext: {
      let ud = UserDefaults.standard
      ud.set($0, forKey: Key.IsHideEditorWhenUnfocused)
      ud.synchronize()
    })
  }
}
