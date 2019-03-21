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
  @IBOutlet private weak var segmentedControl: NSSegmentedControl!
  
  enum Segment: Int {
    case create
    case open
  }
  
  func prepare(segment: Segment) {
    self.segment = segment
  }
  
  private var segment = Segment.create {
    didSet { reloadSegment() }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    parentView.parentViewController = self
    reloadSegment()
  }
  
  @IBAction private func changeSegment(_ sender: NSSegmentedControl) {
    guard let segment = Segment(rawValue: sender.selectedSegment) else { return }
    self.segment = segment
  }
  
  private func reloadSegment() {
    if !isViewLoaded { return }
    segmentedControl.selectedSegment = segment.rawValue
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
    return NSStoryboard(name: "OpenWorkspace", bundle: .main).instantiateInitialController() as! OpenWorkspaceViewController
  }()
  
  private lazy var createWorkspaceViewController: CreateWorkspaceViewController = {
    return NSStoryboard(name: "CreateWorkspace", bundle: .main).instantiateInitialController() as! CreateWorkspaceViewController
    
  }()
}
