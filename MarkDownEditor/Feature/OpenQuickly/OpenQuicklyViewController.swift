//
//  OpenQuicklyViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/28.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxSwift
import RealmSwift

final class OpenQuicklyViewController: NSViewController {
  private let bag = DisposeBag()
  
  private var tableCellHeightCount: CGFloat { return 44 }
  
  @IBOutlet private weak var imageView: NSImageView!
  @IBOutlet private weak var separatorHeightConstraint: NSLayoutConstraint!
  @IBOutlet private weak var tableViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet private weak var searchTextField: OpenQuicklyTextField!
  
  private let result = Variable<Results<NodeModel>>(.empty)
  
  override func viewDidLoad() {
    super.viewDidLoad()
    imageView.image = #imageLiteral(resourceName: "Search").tinted(.text)
    
    searchTextField.rx.text.map { NodeModel.search(query: $0) }.bind(to: result).disposed(by: bag)
    result.asObservable().subscribe(onNext: { [weak self] (result) in
      guard let s = self else { return }
      let resultCount = result.count
      s.separatorHeightConstraint.constant = resultCount == 0 ? 0 : 1
      s.tableViewHeightConstraint.constant = CGFloat(resultCount) * s.tableCellHeightCount
    }).disposed(by: bag)
  }
}

extension OpenQuicklyViewController: NSTableViewDataSource {
  func numberOfRows(in tableView: NSTableView) -> Int {
    return result.value.count
  }
}
