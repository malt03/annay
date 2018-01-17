//
//  WorkspacesViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/17.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class WorkspacesViewController: NSViewController {
  @IBOutlet var workspacesController: NSArrayController!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    workspacesController.content = WorkspaceModel.spaces
  }
}
