//
//  Queue.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/02/27.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Foundation

struct Queue<T> {
  private var array = [T]()
  
  mutating func enqueue(_ value: T) {
    array.append(value)
  }
  
  mutating func dequeue() -> T? {
    if array.last == nil { return nil }
    return array.removeLast()
  }
}
