//
//  ContainerView.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/30.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class ContainerView: BackgroundSetableView {
  weak var parentViewController: NSViewController?
  
  private(set) weak var viewController: NSViewController?
  private var fillConstraints: [NSLayoutConstraint]?
  
  func present(viewController: NSViewController) {
    guard let parent = parentViewController else { return }
    
    isHidden = false
    
    removeCurrentViewController()
    parent.addChild(viewController)
    
    fillConstraints = addSubviewWithFillConstraints(viewController.view)
    self.viewController = viewController
    
    layoutSubtreeIfNeeded()
  }
  
  func dismiss() {
    isHidden = true
    removeCurrentViewController()
  }
  
  private func removeCurrentViewController() {
    if let constraints = fillConstraints {
      removeConstraints(constraints)
      fillConstraints = nil
    }
    viewController?.view.removeFromSuperview()
    viewController?.removeFromParent()
    viewController = nil
  }
}
