//
//  Created by Julien Chaumond on 18/07/2019.
//  Copyright © 2019 Hugging Face. All rights reserved.
//
//  Modifications Copyright (c) 2023, Rei Kitajima.
//

@testable import SwiftTokenizer
import XCTest

struct EncodingSampleDataset: Decodable {
    let text: String
    let token_ids: [Int]
}

enum TestEnv {
    static let dataset: EncodingSampleDataset = {
        let url = Bundle.module.url(forResource: "data", withExtension: "json", subdirectory: "samples/bart")!
        let json = try! Data(contentsOf: url)
        let decoder = JSONDecoder()
        let dataset = try! decoder.decode(EncodingSampleDataset.self, from: json)
        return dataset
    }()

    static let config: TokenizerConfig = TokenizerConfig(
        vocab: Bundle.module.url(forResource: "vocab", withExtension: "json", subdirectory:"bart")!,
        merges: Bundle.module.url(forResource: "merges", withExtension: "txt", subdirectory:"bart")!
    )
}

final class TokenizerTests: XCTestCase {

    func testEncodeForBart() {
        let tokenizer = Tokenizer(config: TestEnv.config)
        XCTAssertEqual(
            tokenizer.appendEOS(tokens: tokenizer.appendBOS(tokens: tokenizer.encode(text: TestEnv.dataset.text))),
            TestEnv.dataset.token_ids
        )
    }

    func testDecodeForBart() {
        let tokenizer = Tokenizer(config: TestEnv.config)
        XCTAssertEqual(
            tokenizer.decode(tokens: tokenizer.stripBOS(tokens: tokenizer.stripEOS(tokens: TestEnv.dataset.token_ids))),
            TestEnv.dataset.text
        )
    }
}
