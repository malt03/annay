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
  @IBOutlet private weak var editorHidingWebParentView: NSView!
  @IBOutlet private weak var progressIndicator: NSProgressIndicator!
  @IBOutlet private weak var editorHidingProgressIndicator: NSProgressIndicator!
  private var webView: WebView!
  private var editorHidingWebView: WebView!
  
  private var isFocusEditor: Observable<Bool> {
    return (view.window as! MainWindow).firstResponderObservable.map { [weak self] (responder) -> Bool in
      guard let s = self else { return false }
      if responder == s.webView { return true }
      if let textView = responder as? NSTextView {
        return textView.searchSuperviews(s.view)
      }
      return false
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    prepareWebView()
    prepareEditorHidingWebView()
    
    NodeModel.selectedNode.asObservable().subscribe(onNext: { [weak self] (node) in
      self?.updateNote(note: node)
    }).disposed(by: bag)
    
    OutlineModel.selected.subscribe(onNext: { [weak self] (outline) in
      guard let s = self else { return }
      s.textView.scrollRangeToVisible(outline.range)
      s.textView.setSelectedRange(outline.range)
      s.webView.jump(outline: outline)
      s.editorHidingWebView.jump(outline: outline)
    }).disposed(by: bag)
    
    prepareTextView()
  }
  
  private func prepareWebView() {
    progressIndicator.startAnimation(nil)
    
    let userController = WKUserContentController()
    userController.add(self, name: "checkboxChanged")
    userController.add(self, name: "fetchImage")
    let webConfiguration = WKWebViewConfiguration()
    webConfiguration.userContentController = userController
    
    webView = WebView(frame: webParentView.bounds, configuration: webConfiguration)
    webParentView.addSubviewWithFillConstraints(webView)
    webView.prepare(hideWhenDragged: false) { [weak self] in
      self?.progressIndicator.stopAnimation(nil)
    }
  }
  
  private func prepareEditorHidingWebView() {
    let userController = WKUserContentController()
    userController.add(self, name: "checkboxChanged")
    userController.add(self, name: "fetchImage")
    userController.add(self, name: "backgroundClicked")
    let webConfiguration = WKWebViewConfiguration()
    webConfiguration.userContentController = userController
    
    editorHidingWebView = WebView(frame: editorHidingWebParentView.bounds, configuration: webConfiguration)
    editorHidingWebParentView.addSubviewWithFillConstraints(editorHidingWebView)
    editorHidingWebView.prepare(hideWhenDragged: true) { [weak self] in
      self?.editorHidingProgressIndicator.stopAnimation(nil)
    }
  }
  
  override func viewWillAppear() {
    super.viewWillAppear()
    NotificationCenter.default.addObserver(self, selector: #selector(moveFocusToEditor), name: .MoveFocusToEditor, object: nil)
  }
  
  override func viewDidAppear() {
    super.viewDidAppear()
    Observable.combineLatest(
      isFocusEditor,
      GeneralPreference.shared.isHideEditorWhenUnfocused.asObservable(),
      resultSelector: { !$0 && $1 }
    ).subscribe(onNext: { [weak self] (isHideEditor) in
      guard let s = self else { return }
      s.editorHidingWebParentView.isHidden = !isHideEditor
    }).disposed(by: bag)
  }
  
  override func viewWillDisappear() {
    NotificationCenter.default.removeObserver(self, name: .MoveFocusToEditor, object: nil)
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
      textView.isEditable = !note.isDeletedWithParent
    } else {
      textView.isEditable = false
    }
    textView.string = note?.body ?? ""
    textView.textStorage?.highlightMarkdownSyntax()
    updateWebView(note: note)
    
    // select()のタイミングがtransaction内になっちゃうので
    DispatchQueue.main.async {
      self.noteChangeNotificationToken?.invalidate()
      self.noteChangeNotificationToken = note?.observe { [weak self] (change) in
        guard let s = self else { return }
        switch change {
        case .deleted: s.updateNote(note: nil)
        default: break
        }
      }
    }
  }
  
  private func updateWebView(note: NodeModel? = NodeModel.selectedNode.value) {
    var markDown = (note?.body ?? "")
    if view.window?.firstResponder == textView {
      let markDownNSString = NSMutableString(string: markDown)
      markDownNSString.insert("$$$$scroll$$$$", at: textView.selectedRange().location)
      markDown = markDownNSString as String
    }
    markDown = markDown.replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\n", with: "\\n")
      .replacingOccurrences(of: "\"", with: "\\\"")

    webView.update(markdown: markDown, completionHandler: { (html) in
      guard let nodeId = note?.id else { return }
      HtmlDataStore.shared.set(nodeId: nodeId, html: html)
    })
    editorHidingWebView.update(markdown: markDown)
  }
  
  private var lastUpdateTextWorkItem: DispatchWorkItem?
}

extension MarkDownEditorViewController: NSTextViewDelegate {
  func textDidChange(_ notification: Notification) {
    lastUpdateTextWorkItem?.cancel()
    let updateTextWorkItem = DispatchWorkItem { [weak self] in
      guard let s = self else { return }
      if let note = NodeModel.selectedNode.value {
        Realm.transaction { _ in
          note.setBody(s.textView.string)
        }
      }
      s.textView.textStorage?.highlightMarkdownSyntax()
      s.updateWebView()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: updateTextWorkItem)
    lastUpdateTextWorkItem = updateTextWorkItem
  }
  
  func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
    switch commandSelector {
    case #selector(textView.insertNewline(_:)):
      textView.insertNewline(nil)
      let selectedRange = textView.selectedRange()
      let text = textView.string as NSString
      let line = text.lineRange(for: NSRange(location: selectedRange.location - 1, length: 1))

      if String(text.substring(with: line)).match(with: "^\\s*(([\\-\\+\\*]|\\d+\\.)( \\[[x ]\\]|)|>+) $") != nil {
        textView.insertText("", replacementRange: line)
        textView.insertNewline(nil)
      } else if let match = text.substring(with: line).match(with: "^\\s*(([\\-\\+\\*]|\\d+\\.)( \\[[x ]\\]|)|>+) ") {
        var replaced = match.replacingOccurrences(of: "[x]", with: "[ ]")
        if let number = replaced.match(with: "\\d+") {
          replaced = replaced.replacingOccurrences(of: number, with: "\(Int(number)! + 1)")
        }
        textView.insertText(replaced, replacementRange: selectedRange)
      }
      return true
    case #selector(textView.insertTab(_:)):
      let selectedRange = textView.selectedRange()
      let text = textView.string as NSString

      if selectedRange.length > 0 {
        let range = text.lineRange(for: selectedRange)
        let lineText = text.substring(with: range)
        let replacedLineText = lineText
          .replacingOccurrences(of: "^", with: "\t", options: .regularExpression)
          .replacingOccurrences(of: "\n", with: "\n\t", options: .regularExpression)
          .replacingOccurrences(of: "\t$", with: "", options: .regularExpression)
        textView.insertText(replacedLineText, replacementRange: range)
        textView.setSelectedRange(NSRange(location: range.location, length: range.length + replacedLineText.split(separator: "\n").count))
      } else {
        let line = text.lineRange(for: NSRange(location: selectedRange.location - 1, length: 1))
        let lineText = text.substring(with: line)
        if lineText.match(with: "^\\s*([\\-\\+\\*]|\\d+\\.)( \\[[x ]\\]|) $") != nil {
          textView.insertText("\t\(lineText)", replacementRange: line)
          textView.moveLeft(nil)
          textView.moveToEndOfLine(nil)
        } else {
          textView.insertTab(nil)
        }
      }
      return true
    case #selector(textView.insertBacktab(_:)):
      let selectedRange = textView.selectedRange()
      let text = textView.string as NSString
      if selectedRange.length > 0 {
        let range = text.lineRange(for: selectedRange)
        let lineText = text.substring(with: range)
        if String(lineText).oldRanges(with: "^\t").count == 0 && String(lineText).oldRanges(with: "\n\t").count == 0 { return true }
        let replacedLineText = lineText
          .replacingOccurrences(of: "^\t", with: "", options: .regularExpression)
          .replacingOccurrences(of: "\n\t", with: "\n", options: .regularExpression)
        textView.insertText(replacedLineText, replacementRange: range)
        textView.setSelectedRange(NSRange(location: range.location, length: range.length - replacedLineText.oldRanges(with: "\n").count))
      } else {
        let line = text.lineRange(for: NSRange(location: selectedRange.location - 1, length: 1))
        
        if text.substring(with: line).match(with: "^\t+") != nil {
          textView.insertText("", replacementRange: NSRange(location: line.location, length: 1))
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
      if !textView.isFirstResponderValue && GeneralPreference.shared.isHideEditorWhenUnfocused.value { moveFocusToEditor() }
    case "checkboxChanged":
      guard
        let note = NodeModel.selectedNode.value,
        let dict = message.body as? [String: Any],
        let content = dict["content"] as? String,
        let index = dict["index"] as? Int,
        let isChecked = dict["isChecked"] as? Int
        else { return }
      alertError { try note.updateCheckbox(content: content, index: index, isChecked: isChecked == 1) }
      updateNote(note: note)
    case "fetchImage":
      guard
        let imageUrlString = message.body as? String,
        let imageUrl = URL(string: imageUrlString)
        else { return }
      if imageUrl.scheme != "file" { return }
      BookmarkManager.shared.getBookmarkedURL(imageUrl, fallback: { () -> URL? in
        return nil
      }, handler: { (bookmarkedUrl) in
        guard let imageData = try? Data(contentsOf: imageUrl) else { return }
        message.webView?.evaluateJavaScript("updateImage(\"\(imageUrlString)\", \"\(imageData.imageTagBase64EncodedSrc)\")", completionHandler: nil)
      })
    default: break
    }
  }
}
