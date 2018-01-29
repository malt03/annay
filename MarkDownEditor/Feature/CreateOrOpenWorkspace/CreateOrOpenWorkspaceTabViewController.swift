//
//  CreateOrOpenWorkspaceTabViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/29.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class CreateOrOpenWorkspaceTabViewController: NSViewController {
  @IBOutlet private weak var parentView: ContainerView!
  
  enum Segment: Int {
    case create
    case open
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    parentView.parentViewController = self
    updateSegment(.create)
  }
  
  @IBAction private func changeSegment(_ sender: NSSegmentedControl) {
    guard let segment = Segment(rawValue: sender.selectedSegment) else { return }
    updateSegment(segment)
  }
  
  private func updateSegment(_ segment: Segment) {
    let vc = viewController(for: segment)
    parentView.present(viewController: vc)
    view.window?.makeFirstResponder(vc)
  }
  
  private func viewController(for segment: Segment) -> NSViewController {
    switch segment {
    case .create: return createWorkspaceViewController
    case .open:   return openWorkspaceViewController
    }
  }
  
  private lazy var openWorkspaceViewController: OpenWorkspaceViewController = {
    return NSStoryboard(name: .init(rawValue: "OpenWorkspace"), bundle: .main).instantiateInitialController() as! OpenWorkspaceViewController
    
  }()
  
  private lazy var createWorkspaceViewController: CreateWorkspaceViewController = {
    return NSStoryboard(name: .init(rawValue: "CreateWorkspace"), bundle: .main).instantiateInitialController() as! CreateWorkspaceViewController
    
  }()
}
