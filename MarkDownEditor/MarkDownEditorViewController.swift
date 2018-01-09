//
//  MarkDownEditorViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/09.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa
import RxCocoa
import RxSwift

final class MarkDownEditorViewController: NSViewController {
  @IBOutlet private weak var textView: TextView!
  @IBOutlet private weak var webView: WebView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    prepareTextView()
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
}

extension MarkDownEditorViewController: NSTextViewDelegate {
  func textDidChange(_ notification: Notification) {
    webView.update(markdown: textView.text.replacingOccurrences(of: "\n", with: "\\n"))
  }
}
