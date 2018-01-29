//
//  NSView+Extensions.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/27.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

extension NSView {
  @discardableResult
  func addSubviewWithFillConstraints(_ view: NSView) -> [NSLayoutConstraint] {
    view.frame = bounds
    addSubview(view)
    
    view.translatesAutoresizingMaskIntoConstraints = false
    
    let hFormat = "|-0-[v]-0-|"
    let vFormat = "V:|-0-[v]-0-|"
    
    let views = ["v": view] as [String: NSView]
    var constraints = [NSLayoutConstraint]()
    constraints += NSLayoutConstraint.constraints(withVisualFormat: hFormat, options: [], metrics: nil, views: views)
    constraints += NSLayoutConstraint.constraints(withVisualFormat: vFormat, options: [], metrics: nil, views: views)
    
    addConstraints(constraints)
    return constraints
  }
}
