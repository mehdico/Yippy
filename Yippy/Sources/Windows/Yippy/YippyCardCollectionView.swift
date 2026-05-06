//
//  YippyCardCollectionView.swift
//  Yippy
//
//  Horizontal stack of square HistoryItem cards (Paste-style).
//  Implemented as NSStackView (not NSCollectionView) inside NSScrollView,
//  to avoid AppKit's NSCollectionView+autolayout recursion.
//

import Cocoa

protocol YippyCardCollectionViewDelegate: AnyObject {
    func cardCollectionView(_ view: YippyCardCollectionView, selectedDidChange selected: Int?)
    func cardCollectionView(_ view: YippyCardCollectionView, pasteItemAt index: Int)
    func cardCollectionView(_ view: YippyCardCollectionView, deleteItemAt index: Int)
}

class YippyCardCollectionView: NSStackView {

    var yippyItems: [HistoryItem] = []
    var isRichText: Bool = true
    weak var yippyDelegate: YippyCardCollectionViewDelegate?

    private(set) var selected: Int? = nil
    private var cards: [YippyCardCellView] = []
    private var cardSizeConstraints: [(NSLayoutConstraint, NSLayoutConstraint)] = []

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        orientation = .horizontal
        alignment = .centerY
        spacing = Constants.panel.cardSpacing
        edgeInsets = NSEdgeInsets(top: 0, left: 10, bottom: 6, right: 10)
        distribution = .gravityAreas
    }

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        // The superview of an NSScrollView's documentView is its NSClipView.
        if let clip = superview as? NSClipView {
            clip.postsBoundsChangedNotifications = true
            NotificationCenter.default.removeObserver(self, name: NSView.boundsDidChangeNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(clipBoundsChanged), name: NSView.boundsDidChangeNotification, object: clip)
        }
    }

    @objc private func clipBoundsChanged() {
        refreshVisibleShortcuts()
    }

    func reloadData(_ data: [HistoryItem], isRichText: Bool) {
        self.yippyItems = data
        self.isRichText = isRichText
        rebuild()
    }

    private func rebuild() {
        for v in cards { v.removeFromSuperview() }
        cards.removeAll()
        cardSizeConstraints.removeAll()

        let size = currentCardSize()
        let first = firstVisibleIndex() ?? 0

        for (i, item) in yippyItems.enumerated() {
            let card = YippyCardCellView()
            card.translatesAutoresizingMaskIntoConstraints = false
            card.cardView.configure(with: item, shortcut: shortcut(for: i, firstVisible: first), isRichText: isRichText)
            card.cardView.isSelected = (selected == i)
            card.onClick = { [weak self] in self?.handleSelect(i) }
            card.onDoubleClick = { [weak self] in
                guard let self = self else { return }
                self.yippyDelegate?.cardCollectionView(self, pasteItemAt: i)
            }
            card.onDelete = { [weak self] in
                guard let self = self else { return }
                self.yippyDelegate?.cardCollectionView(self, deleteItemAt: i)
            }
            addArrangedSubview(card)
            cards.append(card)
            let w = card.widthAnchor.constraint(equalToConstant: size)
            let h = card.heightAnchor.constraint(equalToConstant: size)
            NSLayoutConstraint.activate([w, h])
            cardSizeConstraints.append((w, h))
        }
    }

    private func currentCardSize() -> CGFloat {
        let h = bounds.height - edgeInsets.top - edgeInsets.bottom
        return max(60, h)
    }

    override func layout() {
        super.layout()
        let size = currentCardSize()
        for (w, h) in cardSizeConstraints {
            if w.constant != size { w.constant = size }
            if h.constant != size { h.constant = size }
        }
    }

    private func handleSelect(_ i: Int) {
        selected = i
        for (idx, card) in cards.enumerated() {
            card.cardView.isSelected = (idx == i)
        }
        yippyDelegate?.cardCollectionView(self, selectedDidChange: i)
    }

    func selectItem(_ i: Int) {
        guard i >= 0, i < cards.count else { return }
        selected = i
        for (idx, card) in cards.enumerated() {
            card.cardView.isSelected = (idx == i)
        }
        guard let scroll = enclosingScrollView else { return }
        let clip = scroll.contentView
        let clipWidth = clip.bounds.width
        let originX = clip.bounds.origin.x
        let cardFrame = cards[i].frame

        var newOriginX = originX

        if cardFrame.minX < originX + edgeInsets.left {
            // Target is off-screen to the left: snap so target's left edge aligns to clip.
            newOriginX = cardFrame.minX - edgeInsets.left
        } else if cardFrame.maxX > originX + clipWidth - edgeInsets.right {
            // Target is off-screen to the right: snap so the leftmost visible card is fully shown.
            // Walk from the target leftward until adding the next card would overflow the clip width.
            var leftmost = i
            while leftmost > 0,
                  cardFrame.maxX - cards[leftmost - 1].frame.minX <= clipWidth - edgeInsets.left - edgeInsets.right {
                leftmost -= 1
            }
            newOriginX = cards[leftmost].frame.minX - edgeInsets.left
        }

        if abs(newOriginX - originX) < 0.5 { return }

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.1
            ctx.allowsImplicitAnimation = true
            clip.animator().setBoundsOrigin(NSPoint(x: newOriginX, y: clip.bounds.origin.y))
            scroll.reflectScrolledClipView(clip)
        }
    }

    func deselectItem(_ i: Int) {
        if selected == i { selected = nil }
        if i >= 0, i < cards.count { cards[i].cardView.isSelected = false }
    }

    func reloadItem(_ i: Int) {
        guard i >= 0, i < cards.count, i < yippyItems.count else { return }
        let first = firstVisibleIndex() ?? 0
        cards[i].cardView.configure(with: yippyItems[i], shortcut: shortcut(for: i, firstVisible: first), isRichText: isRichText)
        cards[i].cardView.isSelected = (selected == i)
    }

    /// Index of the leftmost card whose left edge is at or past the visible rect's left edge.
    /// Returns nil if there are no cards.
    func firstVisibleIndex() -> Int? {
        guard let scroll = enclosingScrollView, !cards.isEmpty else { return nil }
        let visibleX = scroll.contentView.bounds.origin.x
        for (i, card) in cards.enumerated() {
            // A card is "visible from the left" if its right edge is past the visible left edge.
            if card.frame.maxX > visibleX + 1 { return i }
        }
        return cards.count - 1
    }

    private func shortcut(for index: Int, firstVisible: Int) -> Int? {
        let offset = index - firstVisible
        return (0..<10).contains(offset) ? offset : nil
    }

    /// Re-applies shortcut numbers on every card based on what's currently visible.
    /// Called as the user scrolls so ⌘0–9 always tracks the leftmost visible card.
    func refreshVisibleShortcuts() {
        let first = firstVisibleIndex() ?? 0
        for (i, card) in cards.enumerated() {
            card.cardView.configure(with: yippyItems[i], shortcut: shortcut(for: i, firstVisible: first), isRichText: isRichText)
            card.cardView.isSelected = (selected == i)
        }
    }
}

class YippyCardCellView: NSView {
    let cardView = YippyCardView()
    var onClick: (() -> Void)?
    var onDoubleClick: (() -> Void)?
    var onDelete: (() -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cardView)
        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount >= 2 {
            onDoubleClick?()
        } else {
            onClick?()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        onClick?()
        let menu = NSMenu(title: "")
        let pasteItem = NSMenuItem(title: "Paste", action: #selector(menuPaste), keyEquivalent: "")
        pasteItem.target = self
        menu.addItem(pasteItem)
        menu.addItem(.separator())
        let deleteItem = NSMenuItem(title: "Delete", action: #selector(menuDelete), keyEquivalent: "")
        deleteItem.target = self
        menu.addItem(deleteItem)
        menu.popUp(positioning: nil, at: convert(event.locationInWindow, from: nil), in: self)
    }

    @objc private func menuPaste() { onDoubleClick?() }
    @objc private func menuDelete() { onDelete?() }
}
