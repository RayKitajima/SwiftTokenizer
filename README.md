
# SwiftTokenizer

Tokenizer for Swift.

Extrated and slightly modified version of GPT2 tokenizer from [swift-coreml-transformers](https://github.com/huggingface/swift-coreml-transformers) to be used as a standalone package. (now especially for BART)


## Swift Package Manager

Add the following to your Package.swift dependencies:

```
  :
dependencies: [
    .package(url: "https://github.com/RayKitajima/SwiftTokenizer.git", from: "1.0.0"),
],
  :
```

## Usage

```swift
import SwiftTokenizer

let config = TokenizerConfig(
    vocab: Bundle.module.url(forResource: "vocab", withExtension: "json")!,
    merges: Bundle.module.url(forResource: "merges", withExtension: "txt")!
)
let tokenizer = Tokenizer(config: config)

let tokens = tokenizer.encode(text: "Hello, world!")
print(tokens)
// [31414, 6, 232, 328]

let decoded = tokenizer.decode(tokens: tokenizer.stripBOS(tokens: tokenizer.stripEOS(tokens: tokens)))
print(decoded)
// Hello, world!
```

In case of BART, you need to append BOS and EOS tokens to the input_ids.

```swift
let input_ids = tokenizer.appendEOS(tokens: tokenizer.appendBOS(tokens: tokenizer.encode(text: "Hello, world!")))
print(tokens)
// [0, 31414, 6, 232, 328, 2]

// inverse
let decoded = tokenizer.decode(tokens: tokenizer.stripBOS(tokens: tokenizer.stripEOS(tokens: input_ids)))
print(decoded)
// Hello, world!
```

## See also

https://github.com/huggingface/swift-coreml-transformers


## License

Apache License 2.0

Copyright © 2019 Hugging Face. All rights reserved.

Modifications copyright (C) 2023 Rei Kitajima (rei.kitajima@gmail.com)
