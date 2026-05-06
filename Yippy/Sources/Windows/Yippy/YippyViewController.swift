//
//  YippyViewController.swift
//  Yippy
//
//  Created by Matthew Davidson on 26/7/19.
//  Copyright © 2019 MatthewDavidson. All rights reserved.
//

import Cocoa
import HotKey
import RxSwift
import RxRelay
import RxCocoa

struct Results {
    let items: [HistoryItem]
    let isSearchResult: Bool
}

class YippyViewController: NSViewController, NSWindowDelegate {
    
    @IBOutlet var yippyHistoryView: YippyTableView!

    @IBOutlet var itemGroupScrollView: HorizontalButtonsView!
    @IBOutlet var itemCountLabel: NSTextField!

    @IBOutlet var searchBar: NSTextField!

    private var cardScrollView: NSScrollView!
    private var cardCollectionView: YippyCardCollectionView!
    private var useHorizontalLayout: Bool = State.main.useHorizontalLayout.value
    
    var yippyHistory = YippyHistory(history: State.main.history, items: [])
    
    var searchEngine = SearchEngine(data: [])
    
    let disposeBag = DisposeBag()
    
    var isPreviewShowing = false
    
    var itemGroups = BehaviorRelay<[String]>(value: ["Clipboard", "Favourites", "Clipboard", "Favourites", "Clipboard", "Favourites"])
    
    var isRichText = Settings.main.showsRichText
    
    let results = BehaviorRelay(value: Results(items: [], isSearchResult: false))
    let selected = BehaviorRelay<Int?>(value: nil)
    
    var globalMonitor: Any?
    var localKeyMonitor: Any?

    private var emptyStateLabel: NSTextField?

    private var lastClosedAt: Date?
    private let searchClearAfter: TimeInterval = 60

    override func viewDidLoad() {
        super.viewDidLoad()

        yippyHistoryView.yippyDelegate = self
        setupCardCollectionView()

        State.main.history.subscribe(onNext: onHistoryChange)

        State.main.showsRichText.distinctUntilChanged().subscribe(onNext: onShowsRichText).disposed(by: disposeBag)
        State.main.useHorizontalLayout.distinctUntilChanged().subscribe(onNext: { [weak self] in self?.onUseHorizontalLayout($0) }).disposed(by: disposeBag)

        itemGroupScrollView.bind(toData: itemGroups.asObservable()).disposed(by: disposeBag)
        itemGroupScrollView.bind(toSelected: BehaviorRelay<Int>(value: 0).asObservable()).disposed(by: disposeBag)
        // TODO: Remove this when implemented
        itemGroupScrollView.constraint(withIdentifier: "height")?.constant = 0

        Observable.combineLatest(
            results,
            selected.distinctUntilChanged().withPrevious(startWith: nil)
        )
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: onAllChange)
            .disposed(by: disposeBag)

        searchBar.delegate = self

        // TODO: Fix hack to make onAllChange run initially
        selected.accept(1)
        resetSelected()
        
        YippyHotKeys.downArrow.onDown(goToNextItem)
        YippyHotKeys.downArrow.onLong(goToNextItem)
        YippyHotKeys.pageDown.onDown(goToNextItem)
        YippyHotKeys.pageDown.onLong(goToNextItem)
        YippyHotKeys.upArrow.onDown(goToPreviousItem)
        YippyHotKeys.upArrow.onLong(goToPreviousItem)
        YippyHotKeys.pageUp.onDown(goToPreviousItem)
        YippyHotKeys.pageUp.onLong(goToPreviousItem)
        YippyHotKeys.leftArrow.onDown(goToPreviousItemHorizontal)
        YippyHotKeys.leftArrow.onLong(goToPreviousItemHorizontal)
        YippyHotKeys.rightArrow.onDown(goToNextItemHorizontal)
        YippyHotKeys.rightArrow.onLong(goToNextItemHorizontal)
        YippyHotKeys.escape.onDown(handleEscape)
        YippyHotKeys.return.onDown(pasteSelected)
        YippyHotKeys.ctrlAltCmdLeftArrow.onDown { State.main.panelPosition.accept(.left) }
        YippyHotKeys.ctrlAltCmdRightArrow.onDown { State.main.panelPosition.accept(.right) }
        YippyHotKeys.ctrlAltCmdDownArrow.onDown { State.main.panelPosition.accept(.bottom) }
        YippyHotKeys.ctrlAltCmdUpArrow.onDown { State.main.panelPosition.accept(.top) }
        YippyHotKeys.ctrlDelete.onDown(deleteSelected)
        YippyHotKeys.ctrlSpace.onDown(togglePreview)
        YippyHotKeys.cmdBackslash.onDown(focusSearchBar)
        
        // Paste hot keys
        YippyHotKeys.cmd0.onDown { self.shortcutPressed(key: 0) }
        YippyHotKeys.cmd1.onDown { self.shortcutPressed(key: 1) }
        YippyHotKeys.cmd2.onDown { self.shortcutPressed(key: 2) }
        YippyHotKeys.cmd3.onDown { self.shortcutPressed(key: 3) }
        YippyHotKeys.cmd4.onDown { self.shortcutPressed(key: 4) }
        YippyHotKeys.cmd5.onDown { self.shortcutPressed(key: 5) }
        YippyHotKeys.cmd6.onDown { self.shortcutPressed(key: 6) }
        YippyHotKeys.cmd7.onDown { self.shortcutPressed(key: 7) }
        YippyHotKeys.cmd8.onDown { self.shortcutPressed(key: 8) }
        YippyHotKeys.cmd9.onDown { self.shortcutPressed(key: 9) }
        
        bindHotKeyToYippyWindow(YippyHotKeys.downArrow, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.upArrow, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.leftArrow, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.rightArrow, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.return, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.escape, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.pageDown, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.pageUp, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.ctrlAltCmdLeftArrow, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.ctrlAltCmdRightArrow, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.ctrlAltCmdDownArrow, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.ctrlAltCmdUpArrow, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd0, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd1, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd2, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd3, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd4, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd5, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd6, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd7, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd8, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd9, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.ctrlDelete, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.ctrlSpace, disposeBag: disposeBag)
        
        searchBar.resignFirstResponder()

        setupEmptyStateLabel()
        updateEmptyStateVisibility()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        attachCardViewIfNeeded()

        if let lastClosed = lastClosedAt,
           Date().timeIntervalSince(lastClosed) > searchClearAfter,
           !searchBar.stringValue.isEmpty {
            searchBar.stringValue = ""
            runSearch()
        }

        isPreviewShowing = false
        resetSelected()
        updateEmptyStateVisibility()

        view.window?.makeFirstResponder(useHorizontalLayout ? cardCollectionView : yippyHistoryView)

        // Add global mouse down monitor
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
            guard let self = self, let window = self.view.window else { return }
            let mouseLocation = NSEvent.mouseLocation
            if !window.frame.contains(mouseLocation) {
                self.close()
            }
        }

        // Type-to-search: forward printable characters to the search field when
        // the user starts typing without explicitly focusing it.
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            return self.handleLocalKeyDown(event) ? nil : event
        }
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()

        lastClosedAt = Date()

        // Remove the global monitor
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localKeyMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyMonitor = nil
        }
    }

    private func handleLocalKeyDown(_ event: NSEvent) -> Bool {
        // Ignore if search field is already first responder — let it handle the event.
        if let firstResponder = view.window?.firstResponder,
           firstResponder === searchBar || firstResponder === searchBar.currentEditor() {
            return false
        }

        // Skip if any non-shift modifier is held — those are commands, not text.
        let disallowed: NSEvent.ModifierFlags = [.command, .control, .option, .function]
        if event.modifierFlags.intersection(disallowed).isEmpty == false {
            return false
        }

        guard let chars = event.charactersIgnoringModifiers, !chars.isEmpty else { return false }

        // Only forward printable, non-control characters.
        let scalar = chars.unicodeScalars.first!
        if scalar.value < 0x20 || scalar.value == 0x7F { return false }

        searchBar.stringValue.append(chars)
        focusSearchBar()
        // Place cursor at end of the search field.
        if let editor = searchBar.currentEditor() {
            editor.selectedRange = NSRange(location: searchBar.stringValue.count, length: 0)
        }
        runSearch()
        return true
    }

    private func setupEmptyStateLabel() {
        let label = NSTextField(labelWithString: "Copy something to get started")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.alignment = .center
        label.textColor = .secondaryLabelColor
        label.font = .systemFont(ofSize: 13)
        label.isHidden = true
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        emptyStateLabel = label
    }

    private func updateEmptyStateVisibility() {
        let isEmpty = yippyHistory.items.isEmpty
        emptyStateLabel?.isHidden = !isEmpty
        if isEmpty {
            emptyStateLabel?.stringValue = searchBar.stringValue.isEmpty
                ? "Copy something to get started"
                : "No matches"
        }
    }
    
    func resetSelected() {
        if yippyHistory.items.count > 0 {
            selected.accept(0)
        }
        else {
            selected.accept(nil)
        }
    }
    
    func onHistoryChange(_ history: [HistoryItem], change: History.Change) {
        updateSearchEngine(items: history)
        if !searchBar.stringValue.isEmpty {
            runSearch()
        }
        else {
            results.accept(Results(items: history, isSearchResult: false))
            switch change {
            case .insert(let i):
                if i == 0 {
                    incrementSelected()
                }
                break;
            default: break;
            }
        }
    }
    
    func updateSearchEngine(items: [HistoryItem]) {
        // Use map (not compactMap) so indices align with items. getPlainTextString
        // surfaces text from RTF/HTML/RTFD items too, so they're searchable.
        self.searchEngine = SearchEngine(data: items.map { $0.getPlainTextString() ?? "" })
    }
    
    func onAllChange(_ results: Results, _ selected: (Int?, Int?)) {
        if results.items != self.yippyHistory.items {
                if results.isSearchResult {
                    self.itemCountLabel.stringValue = "\(results.items.count) matches"
                }
                else {
                    self.itemCountLabel.stringValue = "\(results.items.count) items"
                }

                self.yippyHistory = YippyHistory(history: State.main.history, items: results.items)
                reloadActiveView()
                self.updateEmptyStateVisibility()
            }

        let useCards = useHorizontalLayout && didAttachCardView

        if let previous = selected.0 {
            if useCards {
                cardCollectionView.deselectItem(previous)
                cardCollectionView.reloadItem(previous)
            } else {
                yippyHistoryView.deselectItem(previous)
                yippyHistoryView.reloadItem(previous)
            }
        }
        if let selected = selected.1 {
            if useCards {
                if cardCollectionView.selected != selected {
                    cardCollectionView.selectItem(selected)
                }
                cardCollectionView.reloadItem(selected)
            } else {
                let currentSelection = self.yippyHistoryView.selected
                if currentSelection == nil || currentSelection != selected {
                    self.yippyHistoryView.selectItem(selected)
                }
                self.yippyHistoryView.reloadItem(selected)
            }

            if self.isPreviewShowing {
                State.main.previewHistoryItem.accept(self.yippyHistory.items[selected])
            }
        }
    }

    func onShowsRichText(_ showsRichText: Bool) {
        isRichText = showsRichText
        reloadActiveView()
    }

    private func reloadActiveView() {
        yippyHistoryView.reloadData(yippyHistory.items, isRichText: isRichText)
        if didAttachCardView {
            cardCollectionView.reloadData(yippyHistory.items, isRichText: isRichText)
        }
    }

    private func setupCardCollectionView() {
        cardCollectionView = YippyCardCollectionView()
        cardCollectionView.yippyDelegate = self
        cardCollectionView.translatesAutoresizingMaskIntoConstraints = false

        let scroll = NSScrollView()
        scroll.hasHorizontalScroller = true
        scroll.hasVerticalScroller = false
        scroll.autohidesScrollers = true
        scroll.drawsBackground = false
        scroll.documentView = cardCollectionView
        cardScrollView = scroll

        let clip = scroll.contentView
        NSLayoutConstraint.activate([
            cardCollectionView.topAnchor.constraint(equalTo: clip.topAnchor),
            cardCollectionView.bottomAnchor.constraint(equalTo: clip.bottomAnchor),
            cardCollectionView.leadingAnchor.constraint(equalTo: clip.leadingAnchor),
            cardCollectionView.heightAnchor.constraint(equalTo: clip.heightAnchor),
        ])
    }

    private var didAttachCardView = false

    private func attachCardViewIfNeeded() {
        guard !didAttachCardView else { return }
        guard let scroll = cardScrollView else { return }
        guard let table = yippyHistoryView.enclosingScrollView, let parent = table.superview else { return }

        scroll.translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(scroll)

        // Anchor horizontally + bottom to the table (so cards share its bounds), but
        // anchor the top directly to the item-count label with a card-spacing gap so
        // cards sit snug below the search/title bar instead of inheriting the table's
        // larger storyboard offset.
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: table.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: table.trailingAnchor),
            // Match the visible horizontal gap between cards: a card's visible content
            // sits 4pt inside its outer frame, so card-to-card visible gap is
            // 4 (left inset) + cardSpacing + 4 (right inset) = cardSpacing + 8.
            // Use the same total here.
            scroll.topAnchor.constraint(equalTo: itemCountLabel.bottomAnchor, constant: Constants.panel.cardSpacing + 8),
            scroll.bottomAnchor.constraint(equalTo: table.bottomAnchor),
        ])

        didAttachCardView = true

        applyLayoutVisibility()
        reloadActiveView()
        if useHorizontalLayout, let i = selected.value {
            cardCollectionView.selectItem(i)
        }
    }

    private func onUseHorizontalLayout(_ enabled: Bool) {
        useHorizontalLayout = enabled
        guard didAttachCardView else { return }
        applyLayoutVisibility()
        reloadActiveView()
        if let i = selected.value {
            if enabled { cardCollectionView.selectItem(i) }
            else { yippyHistoryView.selectItem(i) }
        }
    }

    private func applyLayoutVisibility() {
        let table = yippyHistoryView.enclosingScrollView
        table?.isHidden = useHorizontalLayout
        cardScrollView.isHidden = !useHorizontalLayout
        view.window?.makeFirstResponder(useHorizontalLayout ? cardCollectionView : yippyHistoryView)
    }
    
    func bindHotKeyToYippyWindow(_ hotKey: YippyHotKey, disposeBag: DisposeBag) {
        State.main.isHistoryPanelShown
            .distinctUntilChanged()
            .subscribe(onNext: { [] in
                hotKey.isPaused = !$0
            })
            .disposed(by: disposeBag)
    }
    
    func goToNextItem() {
        guard !useHorizontalLayout else { return }
        incrementSelected()
    }

    func goToPreviousItem() {
        guard !useHorizontalLayout else { return }
        decrementSelected()
    }

    func goToNextItemHorizontal() {
        guard useHorizontalLayout else { return }
        incrementSelected()
    }

    func goToPreviousItemHorizontal() {
        guard useHorizontalLayout else { return }
        decrementSelected()
    }
    
    private var activeSelectedIndex: Int? {
        return useHorizontalLayout ? cardCollectionView.selected : yippyHistoryView.selected
    }

    func pasteSelected() {
        if let selected = activeSelectedIndex {
            paste(selected: selected)
        }
    }

    func deleteSelected() {
        if let selected = activeSelectedIndex {
            self.selected.accept(yippyHistory.delete(selected: selected))
        }
    }
    
    func close() {
        isPreviewShowing = false
        State.main.isHistoryPanelShown.accept(false)
        State.main.previewHistoryItem.accept(nil)
        resetSelected()
    }

    func handleEscape() {
        if !searchBar.stringValue.isEmpty {
            searchBar.stringValue = ""
            runSearch()
            view.window?.makeFirstResponder(yippyHistoryView)
        } else {
            close()
        }
    }
    
    func shortcutPressed(key: Int) {
        if useHorizontalLayout, didAttachCardView,
           let first = cardCollectionView.firstVisibleIndex() {
            let target = first + key
            guard target < yippyHistory.items.count else { return }
            paste(selected: target)
        } else {
            paste(selected: key)
        }
    }
    
    func togglePreview() {
        if let selected = activeSelectedIndex {
            isPreviewShowing = !isPreviewShowing
            if isPreviewShowing {
                State.main.previewHistoryItem.accept(yippyHistory.items[selected])
            }
            else {
                State.main.previewHistoryItem.accept(nil)
            }
        }
    }
    
    func focusSearchBar() {
        NSApp.activate(ignoringOtherApps: true)
        self.searchBar.becomeFirstResponder()
    }
    
    func runSearch() {
        searchEngine.search(query: searchBar.stringValue, completion: { result in
            if (result.query.query.isEmpty) {
                self.results.accept(Results(items: State.main.history.items, isSearchResult: false))
                return
            }
            
            var filteredData = [HistoryItem]()
            for i in result.results {
                filteredData.append(State.main.history.items[i])
            }
            
            self.results.accept(Results(items: filteredData, isSearchResult: true))
        })
    }
    
    private func incrementSelected() {
        guard let s = selected.value else {
            if yippyHistory.items.count > 0 {
                selected.accept(0)
            }
            return
        }
        if s < yippyHistory.items.count - 1 {
            selected.accept(s + 1)
        }
    }
    
    private func decrementSelected() {
        guard let s = selected.value else {
            if yippyHistory.items.count > 0 {
                selected.accept(0)
            }
            return
        }
        if s > 0 {
            selected.accept(s - 1)
        }
    }
    
    private func paste(selected: Int) {
        self.close()
        yippyHistory.paste(selected: selected)
    }
}

extension YippyViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        runSearch()
    }
}

extension YippyViewController: YippyCardCollectionViewDelegate {
    func cardCollectionView(_ view: YippyCardCollectionView, selectedDidChange selected: Int?) {
        self.selected.accept(selected)
    }

    func cardCollectionView(_ view: YippyCardCollectionView, pasteItemAt index: Int) {
        guard index >= 0, index < yippyHistory.items.count else { return }
        paste(selected: index)
    }

    func cardCollectionView(_ view: YippyCardCollectionView, deleteItemAt index: Int) {
        guard index >= 0, index < yippyHistory.items.count else { return }
        self.selected.accept(yippyHistory.delete(selected: index))
    }
}

extension YippyViewController: YippyTableViewDelegate {
    func yippyTableView(_ yippyTableView: YippyTableView, selectedDidChange selected: Int?) {
        self.selected.accept(selected)
    }

    func yippyTableView(_ yippyTableView: YippyTableView, didMoveItem from: Int, to: Int) {
        yippyHistory.move(from: from, to: to)
        selected.accept(to)
    }

    func yippyTableView(_ yippyTableView: YippyTableView, pasteItemAt row: Int) {
        guard row >= 0, row < yippyHistory.items.count else { return }
        paste(selected: row)
    }

    func yippyTableView(_ yippyTableView: YippyTableView, deleteItemAt row: Int) {
        guard row >= 0, row < yippyHistory.items.count else { return }
        self.selected.accept(yippyHistory.delete(selected: row))
    }
}
