//
//  SearchEngine.swift
//  Yippy
//
//  Created by Matthew Davidson on 6/9/20.
//  Copyright © 2020 MatthewDavidson. All rights reserved.
//

import Foundation

struct SearchQuery: Hashable, Equatable {

    var query: String

    private init(query: String) {
        self.query = query
    }

    static func fromRawText(_ str: String) -> SearchQuery {
        return SearchQuery(query: str)
    }
}

public class SearchResult {

    var query: SearchQuery
    var results: [Int]
    var items: Int

    var isFinished: Bool { return true }

    init(query: SearchQuery, items: Int, results: [Int] = []) {
        self.query = query
        self.items = items
        self.results = results
    }
}

public class SearchEngine {

    private var cache = [SearchQuery: SearchResult]()
    private let cacheQueue = DispatchQueue(label: "yippy.search.cache")
    private let workQueue = DispatchQueue(label: "yippy.search.work", qos: .userInitiated)

    var data: [String]

    init(data: [String]) {
        self.data = data
    }

    public func search(query: String, completion: @escaping (SearchResult) -> Void) {
        let searchQuery = SearchQuery.fromRawText(query)

        if query.isEmpty {
            completion(SearchResult(query: searchQuery, items: data.count))
            return
        }

        if let cached = cacheQueue.sync(execute: { cache[searchQuery] }) {
            completion(cached)
            return
        }

        let snapshot = data
        workQueue.async { [weak self] in
            guard let self = self else { return }

            // Score every item, drop misses, sort by score descending. Ties break by
            // index ascending (clipboard history is newest-first, so newer wins).
            var scored: [(index: Int, score: Int)] = []
            scored.reserveCapacity(snapshot.count)
            for (i, str) in snapshot.enumerated() {
                if let score = fuzzyScore(needle: query, haystack: str) {
                    scored.append((i, score))
                }
            }
            scored.sort { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                return lhs.index < rhs.index
            }

            let result = SearchResult(query: searchQuery, items: snapshot.count, results: scored.map { $0.index })
            self.cacheQueue.sync { self.cache[searchQuery] = result }
            DispatchQueue.main.async { completion(result) }
        }
    }
}
