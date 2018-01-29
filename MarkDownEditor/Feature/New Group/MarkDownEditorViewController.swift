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

  private var selectedNote: NodeModel?
  
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

    WorkspaceModel.selected.asObservable().subscribe(onNext: { [weak self] _ in
      self?.setSelectedNote(nil)
    }).disposed(by: bag)
    
    prepareTextView()
  }
  
  override func viewWillAppear() {
    super.viewWillAppear()
    NotificationCenter.default.addObserver(self, selector: #selector(noteSelected(_:)), name: .NoteSelected, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(moveFocusToEditor), name: .MoveFocusToEditor, object: nil)
  }
  
  override func viewWillDisappear() {
    NotificationCenter.default.removeObserver(self)
    super.viewWillDisappear()
  }
  
  @objc private func noteSelected(_ notification: Notification) {
    setSelectedNote(notification.object as? NodeModel)
  }
  
  @objc private func moveFocusToEditor() {
    view.window?.makeFirstResponder(textView)
  }
  
  private func setSelectedNote(_ note: NodeModel?) {
    selectedNote = note
    textView.isEditable = selectedNote != nil
    textView.string = note?.body ?? ""
    updateWebView()
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
  
  private func updateWebView() {
    let markDown = (selectedNote?.body ?? "")
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\n", with: "\\n")
    webView.update(markdown: markDown)
  }
}

extension MarkDownEditorViewController: NSTextViewDelegate {
  func textDidChange(_ notification: Notification) {
    if let note = selectedNote {
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
      let note = selectedNote,
      let dict = message.body as? [String: Any],
      let content = dict["content"] as? String,
      let index = dict["index"] as? Int,
      let isChecked = dict["isChecked"] as? Int
      else { return }
    note.updateCheckbox(content: content, index: index, isChecked: isChecked == 1)
    setSelectedNote(note)
  }
}
