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
  
  @IBOutlet private weak var splitView: SplitView!
  @IBOutlet private weak var textView: TextView!
  @IBOutlet private weak var webParentView: NSView!
  @IBOutlet private weak var editorHidingWebParentView: BackgroundSetableView!
  @IBOutlet private weak var progressIndicator: NSProgressIndicator!
  @IBOutlet private weak var editorHidingProgressIndicator: NSProgressIndicator!
  private var webView: WebView!
  private var editorHidingWebView: WebView!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    prepareWebView()
    prepareEditorHidingWebView()
    
    Observable.combineLatest(
      textView.isFirstResponder,
      webView.isFirstResponder,
      GeneralPreferenceManager.shared.isHideEditorWhenUnfocused.asObservable(),
      resultSelector: { !$0 && !$1 && $2 }
    ).subscribe(onNext: { [weak self] (isHideEditor) in
      guard let s = self else { return }
      s.editorHidingWebParentView.isHidden = !isHideEditor
    }).disposed(by: bag)

    NodeModel.selectedNode.asObservable().subscribe(onNext: { [weak self] (node) in
      self?.updateNote(note: node)
    }).disposed(by: bag)
    
    let isSelectedNote = !(NodeModel.selectedNode.value?.isDirectory ?? true)
    if isSelectedNote {
      DispatchQueue.main.async { self.moveFocusToEditor() }
    }
    
    prepareTextView()
  }
  
  private func prepareWebView() {
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
  }
  
  private func prepareEditorHidingWebView() {
    let userController = WKUserContentController()
    userController.add(self, name: "checkboxChanged")
    userController.add(self, name: "backgroundClicked")
    let webConfiguration = WKWebViewConfiguration()
    webConfiguration.userContentController = userController
    
    editorHidingWebView = WebView(frame: editorHidingWebParentView.bounds, configuration: webConfiguration)
    editorHidingWebParentView.addSubviewWithFillConstraints(editorHidingWebView)
    editorHidingWebView.prepare { [weak self] in
      self?.editorHidingProgressIndicator.stopAnimation(nil)
    }
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
  
  private var noteChangeNotificationToken: NotificationToken?
  
  private func updateNote(note: NodeModel? = NodeModel.selectedNode.value) {
    if let note = note {
      textView.isEditable = !note.isDeleted
    } else {
      textView.isEditable = false
    }
    textView.string = note?.body ?? ""
    textView.textStorage?.highlightMarkdownSyntax()
    updateWebView(note: note)
    
    noteChangeNotificationToken?.invalidate()
    noteChangeNotificationToken = note?.observe { [weak self] (change) in
      guard let s = self else { return }
      switch change {
      case .deleted: s.updateNote(note: nil)
      default: break
      }
    }
  }
  
  private func updateWebView(note: NodeModel? = NodeModel.selectedNode.value) {
    let markDown = (note?.body ?? "")
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\n", with: "\\n")
      .replacingOccurrences(of: "\"", with: "\\\"")
    webView.update(markdown: markDown, completionHandler: { (html) in
      guard let nodeId = note?.id else { return }
      HtmlDataStore.shared.set(nodeId: nodeId, workspaceId: WorkspaceModel.selected.value.id, html: html)
    })
    editorHidingWebView.update(markdown: markDown)
  }
}

extension MarkDownEditorViewController: NSTextViewDelegate {
  func textDidChange(_ notification: Notification) {
    if let note = NodeModel.selectedNode.value {
      let workspace = WorkspaceModel.selected.value
      Realm.transaction { _ in
        note.setBody(textView.string, workspace: workspace)
      }
    }
    updateWebView()
    textView.textStorage?.highlightMarkdownSyntax()
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
        textView.insertText("", replacementRange: text.oldRange(from: line))
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

      if selectedRange.length > 0 {
        let range = text.lineRange(for: text.range(from: selectedRange))
        let lineText = text[range]
        let replacedLineText = lineText
          .replacingOccurrences(of: "^", with: "\t", options: .regularExpression)
          .replacingOccurrences(of: "\n", with: "\n\t", options: .regularExpression)
          .replacingOccurrences(of: "\t$", with: "", options: .regularExpression)
        textView.insertText(replacedLineText, replacementRange: text.oldRange(from: range))
        let selectedRange = text.oldRange(from: range)
        textView.setSelectedRange(NSRange(location: selectedRange.location, length: selectedRange.length + replacedLineText.oldRanges(with: "\n").count))
      } else {
        let index = text.index(text.startIndex, offsetBy: selectedRange.location - 1)
        let line = text.lineRange(for: index...index)
        let lineText = String(text[line])
        if lineText.match(with: "^\\s*([\\-\\+\\*]|\\d+\\.)( \\[[x ]\\]|) $") != nil {
          textView.insertText("\t\(lineText)", replacementRange: text.oldRange(from: line))
          textView.moveLeft(nil)
          textView.moveToEndOfLine(nil)
        } else {
          textView.insertTab(nil)
        }
      }
      return true
    case #selector(textView.insertBacktab(_:)):
      let selectedRange = textView.selectedRange()
      let text = textView.string
      if selectedRange.length > 0 {
        let range = text.lineRange(for: text.range(from: selectedRange))
        let lineText = text[range]
        if String(lineText).oldRanges(with: "^\t").count == 0 && String(lineText).oldRanges(with: "\n\t").count == 0 { return true }
        let replacedLineText = lineText
          .replacingOccurrences(of: "^\t", with: "", options: .regularExpression)
          .replacingOccurrences(of: "\n\t", with: "\n", options: .regularExpression)
        textView.insertText(replacedLineText, replacementRange: text.oldRange(from: range))
        let selectedRange = text.oldRange(from: range)
        textView.setSelectedRange(NSRange(location: selectedRange.location, length: selectedRange.length - replacedLineText.oldRanges(with: "\n").count))
      } else {
        let index = text.index(text.startIndex, offsetBy: selectedRange.location - 1)
        let line = text.lineRange(for: index...index)
        
        if String(text[line]).match(with: "^\t+") != nil {
          textView.insertText("", replacementRange: text.oldRange(from: line.lowerBound...text.index(after: line.lowerBound)))
        } else {
          textView.insertBacktab(nil)
        }
      }
      return true
    default: break
    }
    return false
  }
}

extension MarkDownEditorViewController: WKScriptMessageHandler {
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    switch message.name {
    case "backgroundClicked":
      if !textView.isFirstResponderValue && GeneralPreferenceManager.shared.isHideEditorWhenUnfocused.value { moveFocusToEditor() }
    case "checkboxChanged":
      print(textView.isFirstResponderValue)
      guard
        let note = NodeModel.selectedNode.value,
        let dict = message.body as? [String: Any],
        let content = dict["content"] as? String,
        let index = dict["index"] as? Int,
        let isChecked = dict["isChecked"] as? Int
        else { return }
      note.updateCheckbox(content: content, index: index, isChecked: isChecked == 1)
      updateNote(note: note)
    default: break
    }
  }
}
