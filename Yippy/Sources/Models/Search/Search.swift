//
//  Search.swift
//  Yippy
//
//  Created by Matthew Davidson on 6/9/20.
//  Copyright © 2020 MatthewDavidson. All rights reserved.
//

import Foundation

/// Returns a relevance score if `needle` matches `haystack`, otherwise nil.
/// Higher scores are better matches. Substring matches beat subsequence matches.
public func fuzzyScore(needle: String, haystack: String) -> Int? {
    if needle.isEmpty { return 0 }
    if needle.count > haystack.count { return nil }

    let n = needle.lowercased()
    let h = haystack.lowercased()

    // Exact substring match — strongly preferred.
    if let range = h.range(of: n) {
        let pos = h.distance(from: h.startIndex, to: range.lowerBound)
        var score = 10_000 - pos
        if pos == 0 {
            score += 500
        } else {
            let prev = h[h.index(before: range.lowerBound)]
            if !prev.isLetter && !prev.isNumber { score += 250 }
        }
        return score
    }

    // Fall back to scored subsequence match. Reject matches whose span (distance
    // from first to last matched char) is wider than maxSpan — this prevents
    // "yahoo" from matching long sentences just because the letters appear
    // scattered far apart.
    let maxSpan = max(15, n.count * 4)

    var nIdx = n.startIndex
    var hIdx = h.startIndex
    var score = 0
    var prevMatched = false
    var firstMatchPos: Int?
    var lastMatchPos = 0
    var consecutive = 0

    while nIdx != n.endIndex && hIdx != h.endIndex {
        if n[nIdx] == h[hIdx] {
            let pos = h.distance(from: h.startIndex, to: hIdx)
            if firstMatchPos == nil {
                firstMatchPos = pos
            } else if pos - firstMatchPos! > maxSpan {
                return nil
            }
            lastMatchPos = pos
            score += 1
            if prevMatched {
                consecutive += 1
                score += consecutive * 4
            } else {
                consecutive = 0
            }
            if hIdx == h.startIndex {
                score += 8
            } else {
                let prev = h[h.index(before: hIdx)]
                if !prev.isLetter && !prev.isNumber { score += 4 }
            }
            prevMatched = true
            nIdx = n.index(after: nIdx)
        } else {
            prevMatched = false
            consecutive = 0
        }
        hIdx = h.index(after: hIdx)
    }

    if nIdx != n.endIndex { return nil }
    if let first = firstMatchPos, lastMatchPos - first > maxSpan { return nil }

    if let pos = firstMatchPos { score -= pos / 8 }
    return score
}

/// Backwards-compatible Bool API. Prefer `fuzzyScore`.
public func performSearch(needle: String, haystack: String) -> Bool {
    return fuzzyScore(needle: needle, haystack: haystack) != nil
}
