//
//  MarkDownEditorViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/09.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RealmSwift
import RxSwift
import WebKit

final class MarkDownEditorViewController: NSViewController {
  private let bag = DisposeBag()
  
  @IBOutlet private weak var textView: TextView!
  @IBOutlet private weak var webParentView: NSView!
  @IBOutlet private weak var progressIndicator: NSProgressIndicator!
  private var webView: WebView!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    progressIndicator.startAnimation(nil)
    
    let userController = WKUserContentController()
    userController.add(self, name: "checkboxChanged")
    let webConfiguration = WKWebViewConfiguration()
    webConfiguration.userContentController = userController
    
    webView = WebView(frame: webParentView.bounds, configuration: webConfiguration)
    webParentView.addSubviewWithFillConstraints(webView)
    webView.prepare { [weak self] in
      self?.progressIndicator.stopAnimation(nil)
    }

    NodeModel.selectedNode.asObservable().subscribe(onNext: { [weak self] (node) in
      self?.updateNote(note: node)
    }).disposed(by: bag)
    
    prepareTextView()
  }
  
  override func viewWillAppear() {
    super.viewWillAppear()
    NotificationCenter.default.addObserver(self, selector: #selector(moveFocusToEditor), name: .MoveFocusToEditor, object: nil)
  }
  
  override func viewWillDisappear() {
    NotificationCenter.default.removeObserver(self)
    super.viewWillDisappear()
  }
  
  @objc private func moveFocusToEditor() {
    view.window?.makeFirstResponder(textView)
  }
  
  override func cancelOperation(_ sender: Any?) {
    NSApplication.shared.endEditing()
    webView.isHidden = false
  }

  private func prepareTextView() {
    textView.isAutomaticTextCompletionEnabled = false
    textView.isAutomaticTextReplacementEnabled = false
    textView.isAutomaticDashSubstitutionEnabled = false
    textView.isAutomaticQuoteSubstitutionEnabled = false
    textView.isAutomaticSpellingCorrectionEnabled = false
    textView.isContinuousSpellCheckingEnabled = false
    textView.isGrammarCheckingEnabled = false
  }
  
  private func updateNote(note: NodeModel? = NodeModel.selectedNode.value) {
    textView.isEditable = note != nil
    textView.string = note?.body ?? ""
    updateWebView(note: note)
  }
  
  private func updateWebView(note: NodeModel? = NodeModel.selectedNode.value) {
    let markDown = (note?.body ?? "")
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\n", with: "\\n")
    webView.update(markdown: markDown)
  }
}

extension MarkDownEditorViewController: NSTextViewDelegate {
  func textDidChange(_ notification: Notification) {
    if let note = NodeModel.selectedNode.value {
      Realm.transaction { _ in
        note.setBody(textView.string)
      }
    }
    updateWebView()
  }
}

extension MarkDownEditorViewController: WKScriptMessageHandler {
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    guard
      let note = NodeModel.selectedNode.value,
      let dict = message.body as? [String: Any],
      let content = dict["content"] as? String,
      let index = dict["index"] as? Int,
      let isChecked = dict["isChecked"] as? Int
      else { return }
    note.updateCheckbox(content: content, index: index, isChecked: isChecked == 1)
    updateNote(note: note)
  }
}
