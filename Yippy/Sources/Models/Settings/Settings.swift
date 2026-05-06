//
//  Settings.swift
//  Yippy
//
//  Created by Matthew Davidson on 6/8/19.
//  Copyright © 2019 MatthewDavidson. All rights reserved.
//

import Foundation
import Default
import RxSwift
import RxRelay
import HotKey

struct Settings: Codable, DefaultStorable {
    
    // MARK: - Singleton
    
    private init(
        panelPosition: PanelPosition,
        pasteboardChangeCount: Int,
        toggleHotKey: KeyCombo,
        maxHistory: Int,
        showsRichText: Bool,
        pastesRichText: Bool,
        useHorizontalLayout: Bool
    ) {
        self.panelPosition = panelPosition
        self.pasteboardChangeCount = pasteboardChangeCount
        self.toggleHotKey = toggleHotKey
        self.maxHistory = maxHistory
        self.showsRichText = showsRichText
        self.pastesRichText = pastesRichText
        self.useHorizontalLayout = useHorizontalLayout
    }
    
    static var main: Settings! {
        get {
            let settings = Settings.read(forKey: "settings")
            if settings != nil {
                return settings
            }
            return Settings.default
        }
        set (main) {
            main.write(withKey: "settings")
        }
    }
    
    // MARK: - Default
    
    static let `default` = Settings(
        panelPosition: .bottom,
        pasteboardChangeCount: -1,
        toggleHotKey: KeyCombo(key: .v, modifiers: [.command, .shift]),
        maxHistory: Constants.settings.maxHistoryItemsDefault,
        showsRichText: true,
        pastesRichText: true,
        useHorizontalLayout: true
    )
    
    // MARK: - Settings
    
    var panelPosition: PanelPosition
    
    var pasteboardChangeCount: Int
    
    var toggleHotKey: KeyCombo
    
    var maxHistory: Int
    
    var showsRichText: Bool
    
    var pastesRichText: Bool

    var useHorizontalLayout: Bool

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case panelPosition, pasteboardChangeCount, toggleHotKey, maxHistory,
             showsRichText, pastesRichText, useHorizontalLayout
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.panelPosition = try c.decode(PanelPosition.self, forKey: .panelPosition)
        self.pasteboardChangeCount = try c.decode(Int.self, forKey: .pasteboardChangeCount)
        self.toggleHotKey = try c.decode(KeyCombo.self, forKey: .toggleHotKey)
        self.maxHistory = try c.decode(Int.self, forKey: .maxHistory)
        self.showsRichText = try c.decode(Bool.self, forKey: .showsRichText)
        self.pastesRichText = try c.decode(Bool.self, forKey: .pastesRichText)
        self.useHorizontalLayout = try c.decodeIfPresent(Bool.self, forKey: .useHorizontalLayout) ?? true
    }

    // MARK: - State Binding Methods
    
    func bindPanelPositionTo(state: BehaviorRelay<PanelPosition>) -> Disposable {
        return state.bind { (x) in
            Settings.main.panelPosition = x
        }
    }
    
    func bindPasteboardChangeCountTo(state: Observable<Int>) -> Disposable {
        return state.bind { (x) in
            Settings.main.pasteboardChangeCount = x
        }
    }
    
    func bindMaxHistoryTo(state: Observable<Int>) -> Disposable {
        return state.bind { (x) in
            Settings.main.maxHistory = x
        }
    }
    
    func bindShowsRichTextTo(state: Observable<Bool>) -> Disposable {
        return state.bind { (x) in
            Settings.main.showsRichText = x
        }
    }
    
    func bindPastesRichTextTo(state: Observable<Bool>) -> Disposable {
        return state.bind { (x) in
            Settings.main.pastesRichText = x
        }
    }

    func bindUseHorizontalLayoutTo(state: Observable<Bool>) -> Disposable {
        return state.bind { (x) in
            Settings.main.useHorizontalLayout = x
        }
    }
}

extension Settings {
    
    struct testData {
        static var a: Settings {
            var settings = Settings.default
            settings.panelPosition = .left
            return settings
        }
        
        static func from(_ str: String) -> Settings? {
            switch str {
            case "--Settings.testData=a":
                return a
            default:
                return nil
            }
        }
    }
}

extension Settings: Equatable {
    
}
