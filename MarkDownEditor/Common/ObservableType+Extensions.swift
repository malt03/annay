//
//  ObservableType+Extensions.swift
//  Annay
//
//  Created by Koji Murata on 2018/03/11.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import RxSwift

extension ObservableType {
  var void: Observable<Void> { return map { _ in } }
}
