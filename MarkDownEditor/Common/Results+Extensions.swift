//
//  Results+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/28.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import RealmSwift

extension Results where Element: Object {
  var empty: Results {
    return filter("FALSEPREDICATE")
  }
  
  static var empty: Results {
    return Realm.instance.objects(Element.self).empty
  }
}
