# philiprehberger-hex

[![Tests](https://github.com/philiprehberger/rb-hex/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-hex/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-hex.svg)](https://rubygems.org/gems/philiprehberger-hex)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-hex)](https://github.com/philiprehberger/rb-hex/commits/main)

Hex encoding, decoding, and dump formatting for binary data

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-hex"
```

Or install directly:

```bash
gem install philiprehberger-hex
```

## Usage

```ruby
require "philiprehberger/hex"

Philiprehberger::Hex.encode('hello')     # => "68656c6c6f"
Philiprehberger::Hex.decode('68656c6c6f') # => "hello"
```

### Prefix and Uppercase

```ruby
Philiprehberger::Hex.encode('hello', prefix: true)              # => "0x68656c6c6f"
Philiprehberger::Hex.encode('hello', uppercase: true)           # => "68656C6C6F"
Philiprehberger::Hex.encode('hello', prefix: true, uppercase: true) # => "0x68656C6C6F"

Philiprehberger::Hex.decode('0x68656c6c6f')  # => "hello" (auto-strips prefix)
```

### Hex Dump

```ruby
Philiprehberger::Hex.dump("Hello, World!\n")
# 00000000:  4865 6c6c 6f2c 2057 6f72 6c64 210a       Hello, World!.
```

### Grouped Format

```ruby
Philiprehberger::Hex.format('hello', group: 1)  # => "68 65 6c 6c 6f"
Philiprehberger::Hex.format('hello', group: 2)  # => "6865 6c6c 6f"
```

### Validation

```ruby
Philiprehberger::Hex.valid?('abcdef')  # => true
Philiprehberger::Hex.valid?('xyz')     # => false
```

### Byte Array

```ruby
Philiprehberger::Hex.bytes_from('48656c6c6f')  # => [72, 101, 108, 108, 111]
Philiprehberger::Hex.from_bytes([72, 101, 108, 108, 111])  # => "48656c6c6f"
```

### Normalize

```ruby
Philiprehberger::Hex.normalize('0x AA:BB-CC_dd')               # => "aabbccdd"
Philiprehberger::Hex.normalize('0x AA:BB-CC_dd', uppercase: true) # => "AABBCCDD"
```

### Byte Length

```ruby
Philiprehberger::Hex.byte_length('aabbcc')         # => 3
Philiprehberger::Hex.byte_length('0x AA:BB-CC_dd') # => 4
Philiprehberger::Hex.byte_length('')               # => 0
```

### Constant-time Comparison

```ruby
# Safe for comparing MAC/HMAC/signature hex values
Philiprehberger::Hex.secure_equal?('abcd', 'ABCD')  # => true
Philiprehberger::Hex.secure_equal?('aa',   'ab')    # => false
```

### Chunk

```ruby
Philiprehberger::Hex.chunk('aabbccdd', size: 2)    # => ["aabb", "ccdd"]
Philiprehberger::Hex.chunk('aabbccddee', size: 2)  # => ["aabb", "ccdd", "ee"]
```

### Compare

```ruby
Philiprehberger::Hex.compare('aabb', 'aacc')
# => [{ offset: 1, expected: "bb", actual: "cc" }]
```

### Bitwise Operations

```ruby
Philiprehberger::Hex.xor('ff00', '0f0f')  # => "f00f"
Philiprehberger::Hex.and('ff00', '0f0f')  # => "0f00"
Philiprehberger::Hex.or('ff00', '0f0f')   # => "ff0f"
Philiprehberger::Hex.not('ff00')          # => "00ff"
```

### Random Hex

```ruby
Philiprehberger::Hex.random(16)  # => "a3f2b7c891d4e5f6..." (32 hex chars)
```

### Constant Hex

```ruby
Philiprehberger::Hex.zeros(4) # => "00000000"
Philiprehberger::Hex.ones(2)  # => "ffff"
```

### Extract Range

```ruby
Philiprehberger::Hex.extract_range('aabbccdd', offset: 1, length: 2)  # => "bbcc"
```

### Swap Endian

```ruby
Philiprehberger::Hex.swap_endian('aabbccdd')  # => "ddccbbaa"
```

### Pad

```ruby
Philiprehberger::Hex.pad('ff', length: 4)                # => "000000ff"
Philiprehberger::Hex.pad('ff', length: 4, side: :right)  # => "ff000000"
```

### Integer Conversion

```ruby
Philiprehberger::Hex.to_int('ff')              # => 255
Philiprehberger::Hex.from_int(255)             # => "ff"
Philiprehberger::Hex.from_int(255, bytes: 4)   # => "000000ff"
```

### Binary String

```ruby
Philiprehberger::Hex.to_binary_string('aabb')             # => "1010101010111011"
Philiprehberger::Hex.to_binary_string('aabb', group: 4)   # => "1010 1010 1011 1011"
Philiprehberger::Hex.to_binary_string('0xff')             # => "11111111"

Philiprehberger::Hex.from_binary_string('11111111')           # => "ff"
Philiprehberger::Hex.from_binary_string('1010 1010 1011 1011') # => "aabb"
```

### Bit Population Count

```ruby
Philiprehberger::Hex.popcount('0000')   # => 0
Philiprehberger::Hex.popcount('ffff')   # => 16
Philiprehberger::Hex.popcount('5a')     # => 4   (01011010)
Philiprehberger::Hex.popcount('0xff')   # => 8
```

Counts the number of `1` bits in the encoded value. Useful for bitset
cardinality, Bloom-filter density, and Hamming-weight computations on
hex-encoded bit vectors.

## API

| Method | Description |
|--------|-------------|
| `Hex.encode(str, prefix:, uppercase:)` | Encode a string to hexadecimal with optional prefix and case |
| `Hex.decode(hex)` | Decode a hexadecimal string to binary (auto-strips `0x`) |
| `Hex.dump(str)` | Produce an xxd-style hex dump |
| `Hex.format(str, group:)` | Format hex output with configurable grouping |
| `Hex.valid?(str)` | Check if a string is valid hexadecimal |
| `Hex.bytes_from(hex)` | Convert a hex string to an integer byte array |
| `Hex.from_bytes(bytes)` | Build a hex string from an integer byte array |
| `Hex.normalize(hex, uppercase:)` | Strip prefix, whitespace, and separators; return canonical hex |
| `Hex.byte_length(hex)` | Return the decoded byte count after normalising prefix and whitespace, without decoding |
| `Hex.secure_equal?(hex1, hex2)` | Constant-time hex comparison, safe for MAC/HMAC checks |
| `Hex.chunk(hex, size:)` | Split a hex string into an array of byte-aligned chunks |
| `Hex.compare(hex1, hex2)` | Compare two hex strings and return byte-level differences |
| `Hex.xor(hex1, hex2)` | XOR two hex strings and return the hex result |
| `Hex.and(hex1, hex2)` | Bitwise AND of two hex strings |
| `Hex.or(hex1, hex2)` | Bitwise OR of two hex strings |
| `Hex.not(hex)` | Bitwise NOT (one's complement) of a hex string |
| `Hex.random(n)` | Generate a random hex string of n bytes |
| `Hex.zeros(bytes)` | Hex string of `bytes` zero bytes |
| `Hex.ones(bytes)` | Hex string of `bytes` all-ones bytes |
| `Hex.extract_range(hex, offset:, length:)` | Extract a range of bytes from a hex string |
| `Hex.swap_endian(hex)` | Reverse byte order of a hex string |
| `Hex.pad(hex, length:, side:)` | Pad hex string to target byte length with zeros |
| `Hex.to_int(hex)` | Convert a hex string to an integer |
| `Hex.from_int(int, bytes:)` | Convert an integer to a hex string |
| `Hex.to_binary_string(hex, group:)` | Convert a hex string to a binary digit string, with optional bit grouping |
| `Hex.from_binary_string(binary)` | Convert a binary digit string to a lowercase hex string |
| `Hex.popcount(hex)` | Count the number of `1` bits in a hex string (Hamming weight) |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-hex)

🐛 [Report issues](https://github.com/philiprehberger/rb-hex/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-hex/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
