//
//  Created by Julien Chaumond on 18/07/2019.
//  Copyright © 2019 Hugging Face. All rights reserved.
//
//  Modifications Copyright (c) 2023, Rei Kitajima.
//

import Foundation

struct BytePair: Hashable {
    let a: String
    let b: String
    init(_ a: String, _ b: String) {
        self.a = a
        self.b = b
    }

    init(tuple: [String]) {
        a = tuple[0]
        b = tuple[1]
    }

    static func == (lhs: BytePair, rhs: BytePair) -> Bool {
        return lhs.a == rhs.a && lhs.b == rhs.b
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(a)
        hasher.combine(b)
    }
}

private extension String {
    func ranges(of string: String, options: CompareOptions = .regularExpression) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var start = startIndex
        while let range = range(of: string, options: options, range: start ..< endIndex) {
            result.append(range)
            start = range.lowerBound < range.upperBound ? range.upperBound : index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}

class Tokenizer {
    let bpeRanks: [BytePair: Int]
    private let encoder: [String: Int]
    private let decoder: [Int: String]

    init(config: TokenizerConfig) {
        let bpeMergesTxt = try! String(contentsOf: config.merges)
        let arr = bpeMergesTxt.split(separator: "\n").map { String($0) }
        var bpeRanks: [BytePair: Int] = [:]
        for i in 1 ..< arr.count {
            let tuple = arr[i].split(separator: " ").map { String($0) }
            let bp = BytePair(tuple: tuple)
            bpeRanks[bp] = i - 1
        }
        self.bpeRanks = bpeRanks

        encoder = {
            let json = try! Data(contentsOf: config.vocab)
            let decoder = JSONDecoder()
            let vocab = try! decoder.decode([String: Int].self, from: json)
            return vocab
        }()
        decoder = Utils.invert(encoder)
    }

    func byteEncode(text: String) -> [String] {
        let RE = #"'s|'t|'re|'ve|'m|'ll|'d| ?\p{L}+| ?\p{N}+| ?[^\s\p{L}\p{N}]+|\s+(?!\S)|\s+"#
        let tokens = text.ranges(of: RE).map { String(text[$0]) }
        return tokens.map { token -> String in
            Array(token.utf8).map { byteEncoder[$0]! }.joined()
        }
    }

    private func getPairs(word: [String]) -> Set<BytePair> {
        var s = Set<BytePair>()
        for i in 0 ..< word.count - 1 {
            let bp = BytePair(
                word[i],
                word[i + 1]
            )
            s.insert(bp)
        }
        return s
    }

    func bpe(token: String) -> String {
        if token.count <= 1 {
            return token
        }

        var word = Array(token).map { String($0) }
        var pairs = Array(getPairs(word: word))

        while true {
            let bigrams = pairs.filter { bp -> Bool in bpeRanks[bp] != nil }
            if bigrams.count == 0 {
                break
            }
            let bigram = bigrams.min { bp1, bp2 -> Bool in
                bpeRanks[bp1]! < bpeRanks[bp2]!
            }!
            let first = bigram.a
            let second = bigram.b
            var newWord: [String] = []
            var i = 0
            while i < word.count {
                if let j = word[i ..< word.count].firstIndex(of: first) {
                    newWord.append(contentsOf: word[i ..< j])
                    i = j
                } else {
                    newWord.append(contentsOf: word[i ..< word.count])
                    break
                }

                if word[i] == first && i < word.count - 1 && word[i + 1] == second {
                    newWord.append(first + second)
                    i += 2
                } else {
                    newWord.append(word[i])
                    i += 1
                }
            }
            word = newWord
            if word.count == 1 {
                break
            } else {
                pairs = Array(getPairs(word: word))
            }
        }
        return word.joined(separator: " ")
    }

    func appendBOS(tokens: [Int]) -> [Int] {
        return [encoder["<s>"]!] + tokens
    }

    func appendEOS(tokens: [Int]) -> [Int] {
        return tokens + [encoder["</s>"]!]
    }

    func stripBOS(tokens: [Int]) -> [Int] {
        if tokens[0] == encoder["<s>"]! {
            return Array(tokens[1 ..< tokens.count])
        }
        return tokens
    }

    func stripEOS(tokens: [Int]) -> [Int] {
        if tokens[tokens.count - 1] == encoder["</s>"]! {
            return Array(tokens[0 ..< tokens.count - 1])
        }
        return tokens
    }

    func tokenize(text: String) -> [String] {
        var tokens: [String] = []
        for token in byteEncode(text: text) {
            let xx = bpe(token: token).split(separator: " ").map { String($0) }
            tokens.append(contentsOf: xx)
        }
        return tokens
    }

    func encode(text: String) -> [Int] {
        return tokenize(text: text).map { encoder[$0]! }
    }

    func decode(tokens: [Int]) -> String {
        let text = tokens.map { decoder[$0]! }.joined(separator: "")
        let utfCodepoints = text.map { byteDecoder[String($0)]! }
        return String(decoding: utfCodepoints, as: UTF8.self)
    }
}
