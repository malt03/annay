//
//  MarkDownEditorViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/09.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RealmSwift

final class MarkDownEditorViewController: NSViewController {
  @IBOutlet private weak var textView: TextView!
  @IBOutlet private weak var webView: WebView!
  
  private var selectedNote: NodeModel?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    prepareTextView()
  }
  
  override func viewWillAppear() {
    super.viewWillAppear()
    NotificationCenter.default.addObserver(self, selector: #selector(noteSelected(_:)), name: .NoteSelected, object: nil)
  }
  
  override func viewWillDisappear() {
    NotificationCenter.default.removeObserver(self)
    super.viewWillDisappear()
  }
  
  @objc private func noteSelected(_ notification: Notification) {
    setSelectedNote(notification.object as? NodeModel)
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
    let markDown = (selectedNote?.body ?? "").replacingOccurrences(of: "\n", with: "\\n")
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
