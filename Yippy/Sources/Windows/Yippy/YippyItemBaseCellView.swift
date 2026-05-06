//
//  YippyItemBaseCellView.swift
//  Yippy
//
//  Created by Matthew Davidson on 13/10/19.
//  Copyright © 2019 MatthewDavidson. All rights reserved.
//

import Foundation
import Cocoa

/// Abstract base class for all Yippy collection view items.
///
/// Creates and sets up the `contentView`, `shortcutTextView` and the `itemTextView`.
///
/// Handles highlight changes.
class YippyItemBaseCellView: NSTableCellView {
    
    static let contentViewInsets = NSEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    
    class var identifier: NSUserInterfaceItemIdentifier {
        NSUserInterfaceItemIdentifier("YippyItemBaseCellView")
    }
    
    var contentView: YippyItemContentView!
    var shortcutTextView: YippyItemCellTextView!
    var itemTextView: YippyItemCellTextView!

    let sourceIconView = NSImageView()
    let sourceNameLabel = NSTextField(labelWithString: "")
    let sourceStack = NSStackView()
    
    private var lastSetSelected: Bool?
    
    override func updateLayer() {
        super.updateLayer()
        
        guard let lastSetSelected = self.lastSetSelected else { return }
        if !lastSetSelected { return }
        guard #available(OSX 10.14, *) else { return }
        layer?.backgroundColor = NSColor.controlAccentColor.cgColor
    }
    
    static let shortcutStringAttributes: [NSAttributedString.Key: Any] = [
        .font: Constants.fonts.yippyPlainText,
        .foregroundColor: NSColor.white.withAlphaComponent(0.7)
    ]
    
    func setHighlight(isSelected: Bool) {
        var highlightColor = NSColor.systemBlue.withAlphaComponent(0.7).cgColor
        if #available(OSX 10.14, *) {
            highlightColor = NSColor.controlAccentColor.cgColor
        }
        
        layer?.backgroundColor = isSelected ? highlightColor : NSColor.clear.cgColor
        self.lastSetSelected = isSelected
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    func commonInit() {
        contentView = YippyItemContentView(frame: .zero)
        addSubview(contentView)
        itemTextView = YippyItemCellTextView(frame: .zero)
        contentView.addSubview(itemTextView)
        shortcutTextView = YippyItemCellTextView(frame: .zero)
        contentView.addSubview(shortcutTextView)
        
        wantsLayer = true
        layer?.cornerRadius = 10
        itemTextView.drawsBackground = false
        itemTextView.setAccessibilityIdentifier(Accessibility.identifiers.yippyItemTextView)
        
        setupContentView()
        setupShortcutTextView()
        setupSourceStack()
    }

    private func setupSourceStack() {
        sourceIconView.translatesAutoresizingMaskIntoConstraints = false
        sourceIconView.imageScaling = .scaleProportionallyDown
        sourceNameLabel.font = NSFont.systemFont(ofSize: 9)
        sourceNameLabel.textColor = .secondaryLabelColor
        sourceNameLabel.maximumNumberOfLines = 1
        sourceNameLabel.lineBreakMode = .byTruncatingTail
        sourceStack.translatesAutoresizingMaskIntoConstraints = false
        sourceStack.orientation = .horizontal
        sourceStack.spacing = 3
        sourceStack.alignment = .centerY
        sourceStack.addArrangedSubview(sourceIconView)
        sourceStack.addArrangedSubview(sourceNameLabel)
        sourceStack.wantsLayer = true
        sourceStack.layer?.zPosition = 1
        sourceStack.isHidden = true
        contentView.addSubview(sourceStack)
        NSLayoutConstraint.activate([
            sourceStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            sourceStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -3),
            sourceIconView.widthAnchor.constraint(equalToConstant: 12),
            sourceIconView.heightAnchor.constraint(equalToConstant: 12),
            sourceNameLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 140),
        ])
    }

    func applySourceApp(forItem item: HistoryItem) {
        if let name = item.getSourceAppName() {
            sourceStack.isHidden = false
            sourceNameLabel.stringValue = name
            sourceIconView.image = item.getSourceAppIcon()
        } else {
            sourceStack.isHidden = true
            sourceNameLabel.stringValue = ""
            sourceIconView.image = nil
        }
    }
    
    func setupContentView() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = 7
        
        addConstraint(NSLayoutConstraint(item: contentView!, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: Self.contentViewInsets.left))
        addConstraint(NSLayoutConstraint(item: contentView!, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: Self.contentViewInsets.top))
        addConstraint(NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1, constant: Self.contentViewInsets.right))
        addConstraint(NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1, constant: Self.contentViewInsets.bottom))
    }
    
    func setupShortcutTextView() {
        shortcutTextView.translatesAutoresizingMaskIntoConstraints = false
        shortcutTextView.wantsLayer = true
        shortcutTextView.isSelectable = false
        shortcutTextView.textContainer?.lineFragmentPadding = 0
        shortcutTextView.alignment = .right
        shortcutTextView.textContainerInset = NSSize(width: 5, height: 2)
        shortcutTextView.layer?.cornerRadius = 7
        shortcutTextView.layer?.maskedCorners = .layerMinXMaxYCorner
        shortcutTextView.isHorizontallyResizable = false
        shortcutTextView.isVerticallyResizable = false
        shortcutTextView.backgroundColor = NSColor(named: NSColor.Name("ShortcutBackgroundColor"))!
        if #available(OSX 10.14, *) {
            shortcutTextView.backgroundColor = NSColor.controlAccentColor
        }
        shortcutTextView.layer?.zPosition = 1
        
        contentView.addConstraint(NSLayoutConstraint(item: shortcutTextView!, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: 0))
        contentView.addConstraint(NSLayoutConstraint(item: contentView!, attribute: .trailing, relatedBy: .equal, toItem: shortcutTextView, attribute: .trailing, multiplier: 1, constant: 0))
        shortcutTextView.widthAnchor.constraint(equalToConstant: 0, withIdentifier: "width")?.isActive = true
        shortcutTextView.heightAnchor.constraint(equalToConstant: 0, withIdentifier: "height")?.isActive = true
    }
    
    func getShortcutTextViewSize() -> NSSize {
        // Determine the size of the text in one line
        let bRect = shortcutTextView.attributedString().getSingleLineSize()
        return NSSize(width: bRect.width + shortcutTextView.textContainer!.lineFragmentPadding + shortcutTextView.textContainerInset.width * 2, height: bRect.height + shortcutTextView.textContainerInset.height * 2)
    }
    
    func updateShortcutTextViewContraints() {
        let size = getShortcutTextViewSize()
        shortcutTextView.constraint(withIdentifier: "width")?.constant = ceil(size.width)
        shortcutTextView.constraint(withIdentifier: "height")?.constant = ceil(size.height)
    }
    
    func setupShortcutTextView(at i: Int) {
        let shortcutStr = NSAttributedString(string: i < 10 ? "⌘ + \(i)" : "", attributes: Self.shortcutStringAttributes)
        shortcutTextView.attributedText = shortcutStr
        shortcutTextView.isHidden = i >= 10
        updateShortcutTextViewContraints()
    }
    
    private func enclosingYippyTableView() -> YippyTableView? {
        var v: NSView? = self.superview
        while v != nil {
            if let t = v as? YippyTableView { return t }
            v = v?.superview
        }
        return nil
    }

    override func rightMouseDown(with event: NSEvent) {
        guard let tableView = enclosingYippyTableView() else { return }
        let row = tableView.row(for: self)
        guard row >= 0, row < tableView.yippyItems.count else { return }

        tableView.selectItem(row)
        tableView.yippyDelegate?.yippyTableView(tableView, selectedDidChange: row)

        let item = tableView.yippyItems[row]

        let menu = NSMenu(title: "")

        let pasteItem = NSMenuItem(title: "Paste", action: #selector(menuPaste(_:)), keyEquivalent: "")
        pasteItem.target = self
        pasteItem.representedObject = row
        menu.addItem(pasteItem)

        let copyItem = NSMenuItem(title: "Copy", action: #selector(menuCopy(_:)), keyEquivalent: "")
        copyItem.target = self
        copyItem.representedObject = row
        menu.addItem(copyItem)

        if item.getFileUrl() != nil {
            menu.addItem(.separator())
            let revealItem = NSMenuItem(title: "Reveal in Finder", action: #selector(menuReveal(_:)), keyEquivalent: "")
            revealItem.target = self
            revealItem.representedObject = row
            menu.addItem(revealItem)
        }

        menu.addItem(.separator())
        let deleteItem = NSMenuItem(title: "Delete", action: #selector(menuDelete(_:)), keyEquivalent: "")
        deleteItem.target = self
        deleteItem.representedObject = row
        menu.addItem(deleteItem)

        menu.popUp(positioning: nil, at: convert(event.locationInWindow, from: nil), in: self)
    }

    @objc private func menuPaste(_ sender: NSMenuItem) {
        guard let tableView = enclosingYippyTableView(), let row = sender.representedObject as? Int else { return }
        tableView.yippyDelegate?.yippyTableView(tableView, pasteItemAt: row)
    }

    @objc private func menuCopy(_ sender: NSMenuItem) {
        guard let tableView = enclosingYippyTableView(), let row = sender.representedObject as? Int,
              row < tableView.yippyItems.count else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([tableView.yippyItems[row]])
    }

    @objc private func menuReveal(_ sender: NSMenuItem) {
        guard let tableView = enclosingYippyTableView(), let row = sender.representedObject as? Int,
              row < tableView.yippyItems.count,
              let url = tableView.yippyItems[row].getFileUrl() else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    @objc private func menuDelete(_ sender: NSMenuItem) {
        guard let tableView = enclosingYippyTableView(), let row = sender.representedObject as? Int else { return }
        tableView.yippyDelegate?.yippyTableView(tableView, deleteItemAt: row)
    }
}
