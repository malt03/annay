//
//  ObservableType+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/29.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import RxSwift

extension ObservableType where E == Array<WorkspaceModel> {
  func distinctUntilChanged()
    -> Observable<E> {
      return self.distinctUntilChanged({ $0 }, comparer: { ($0 == $1) })
  }
}
