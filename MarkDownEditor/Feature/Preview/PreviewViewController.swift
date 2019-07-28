//
//  PreviewViewController.swift
//  Annay
//
//  Created by Koji Murata on 2019/07/27.
//  Copyright © 2019 Koji Murata. All rights reserved.
//

import Cocoa
import RealmSwift
import RxSwift
import WebKit

final class PreviewViewController: NSViewController {
  private let bag = DisposeBag()
  
  @IBOutlet private weak var progressIndicator: NSProgressIndicator!

  private var webView: WebView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    prepareWebView()
    
    NodeModel.selectedNode.asObservable().subscribe(onNext: { [weak self] (node) in
      self?.updateNote(note: node, notify: false)
    }).disposed(by: bag)
    
    OutlineModel.selected.subscribe(onNext: { [weak self] (outline) in
      guard let s = self else { return }
      s.webView.jump(outline: outline)
    }).disposed(by: bag)
    
    NoteChangeNotification.subject.subscribe(onNext: { [weak self] (notification) in
      guard let s = self else { return }
      if notification.sender == s { return }
      s.updateNote(note: notification.note, notify: false)
    }).disposed(by: bag)
  }
  
  private func prepareWebView() {
    progressIndicator.startAnimation(nil)
    
    let userController = WKUserContentController()
    userController.add(self, name: "checkboxChanged")
    userController.add(self, name: "fetchImage")
    let webConfiguration = WKWebViewConfiguration()
    webConfiguration.userContentController = userController
    
    webView = WebView(frame: view.bounds, configuration: webConfiguration)
    view.addSubviewWithFillConstraints(webView)
    webView.prepare(hideWhenDragged: false) { [weak self] in
      self?.progressIndicator.stopAnimation(nil)
    }
  }
  
  private var noteChangeNotificationToken: NotificationToken?
  
  private func updateNote(note: NodeModel? = NodeModel.selectedNode.value, notify: Bool) {
    updateWebView(note: note, notify: notify)
    
    // select()のタイミングがtransaction内になっちゃうので
    DispatchQueue.main.async {
      self.noteChangeNotificationToken?.invalidate()
      self.noteChangeNotificationToken = note?.observe { [weak self] (change) in
        guard let s = self else { return }
        switch change {
        case .deleted: s.updateNote(note: nil, notify: false)
        default: break
        }
      }
    }
  }
  
  private func updateWebView(note: NodeModel? = NodeModel.selectedNode.value, notify: Bool) {
    if notify {
      NoteChangeNotification.subject.onNext(.init(sender: self, note: note))
    }

    let markDown = (note?.body ?? "").replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\n", with: "\\n")
      .replacingOccurrences(of: "\"", with: "\\\"")
    
    webView.update(markdown: markDown)
  }
}

extension PreviewViewController: WKScriptMessageHandler {
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    switch message.name {
    case "checkboxChanged":
      guard
        let note = NodeModel.selectedNode.value,
        let dict = message.body as? [String: Any],
        let content = dict["content"] as? String,
        let index = dict["index"] as? Int,
        let isChecked = dict["isChecked"] as? Int
        else { return }
      alertError { try note.updateCheckbox(content: content, index: index, isChecked: isChecked == 1) }
      updateNote(note: note, notify: true)
    case "fetchImage":
      guard
        let imageUrlString = message.body as? String,
        let imageUrl = URL(string: imageUrlString)
        else { return }
      if imageUrl.scheme != "file" { return }
      BookmarkManager.shared.getBookmarkedURL(imageUrl, fallback: { imageUrl }, handler: { (bookmarkedUrl) in
        guard let imageData = try? Data(contentsOf: imageUrl) else { return }
        message.webView?.evaluateJavaScript("updateImage(\"\(imageUrlString)\", \"\(imageData.imageTagBase64EncodedSrc)\")", completionHandler: nil)
      })
    default: break
    }
  }

}
