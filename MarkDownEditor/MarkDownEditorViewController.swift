//
//  MarkDownEditorViewController.swift
//  MarkDownEditor
//
//  Created by Koji Murata on 2018/01/09.
//  Copyright © 2018年 Koji Murata. All rights reserved.
//

import Cocoa

final class MarkDownEditorViewController: NSViewController {
  @IBOutlet private var textView: NSTextView!

  override func viewDidLoad() {
    super.viewDidLoad()
    prepareTextView()
  }
  
  override func cancelOperation(_ sender: Any?) {
    NSApplication.shared.endEditing()
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
