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
    
    let isSelectedNote = !(NodeModel.selectedNode.value?.isDirectory ?? true)
    if isSelectedNote {
      DispatchQueue.main.async { self.moveFocusToEditor() }
    }
    
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
    view.window?.makeKeyAndOrderFront(nil)
    view.window?.makeFirstResponder(textView)
  }
  
  override func cancelOperation(_ sender: Any?) {
    NotificationCenter.default.post(name: .MoveFocusToSidebar, object: nil)
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
    if let note = note {
      textView.isEditable = !note.isDeleted
    } else {
      textView.isEditable = false
    }
    textView.string = note?.body ?? ""
    updateWebView(note: note)
  }
  
  private func updateWebView(note: NodeModel? = NodeModel.selectedNode.value) {
    let markDown = (note?.body ?? "")
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\n", with: "\\n")
      .replacingOccurrences(of: "\"", with: "\\\"")
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
  
  func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
    switch commandSelector {
    case #selector(textView.insertNewline(_:)):
      textView.insertNewline(nil)
      let selectedRange = textView.selectedRange()
      let text = textView.string
      let index = text.index(text.startIndex, offsetBy: selectedRange.location - 1)
      let line = text.lineRange(for: index...index)
      
      if String(text[line]).match(with: "^\\s*(([\\-\\+\\*]|\\d+\\.)( \\[[x ]\\]|)|>+) $") != nil {
        textView.replaceCharacters(in: text.oldRange(from: line), with: "")
        textView.insertNewline(nil)
      } else if let match = String(text[line]).match(with: "^\\s*(([\\-\\+\\*]|\\d+\\.)( \\[[x ]\\]|)|>+) ") {
        var replaced = match.replacingOccurrences(of: "[x]", with: "[ ]")
        if let number = replaced.match(with: "\\d+") {
          replaced = replaced.replacingOccurrences(of: number, with: "\(Int(number)! + 1)")
        }
        textView.insertText(replaced, replacementRange: selectedRange)
      }
      return true
    case #selector(textView.insertTab(_:)):
      let selectedRange = textView.selectedRange()
      let text = textView.string
      let index = text.index(text.startIndex, offsetBy: selectedRange.location - 1)
      let line = text.lineRange(for: index...index)
      let lineText = String(text[line])
      
      if lineText.match(with: "^\\s*([\\-\\+\\*]|\\d+\\.)( \\[[x ]\\]|) $") != nil {
        textView.replaceCharacters(in: text.oldRange(from: line), with: "\t\(lineText)")
      } else {
        textView.insertTab(nil)
      }
      return true
    case #selector(textView.insertBacktab(_:)):
      let selectedRange = textView.selectedRange()
      let text = textView.string
      let index = text.index(text.startIndex, offsetBy: selectedRange.location - 1)
      let line = text.lineRange(for: index...index)
      
      if String(text[line]).match(with: "^\t+") != nil {
        textView.replaceCharacters(in: text.oldRange(from: line.lowerBound...text.index(after: line.lowerBound)), with: "")
      } else {
        textView.insertBacktab(nil)
      }
      return true
    default: break
    }
    return false
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
