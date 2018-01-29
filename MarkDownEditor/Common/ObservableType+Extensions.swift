//
//  ObservableType+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/29.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import RxSwift

extension ObservableType {
  public func nwise(_ n: Int) -> Observable<[E]> {
    return self
      .scan([]) { acc, item in Array((acc + [item]).suffix(n)) }
      .filter { $0.count == n }
  }
  
  public var pairwised: Observable<(E, E)> {
    return self.nwise(2)
      .map { ($0[0], $0[1]) }
  }
}
