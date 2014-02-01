# philiprehberger-hex

[![Tests](https://github.com/philiprehberger/rb-hex/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-hex/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-hex.svg)](https://rubygems.org/gems/philiprehberger-hex)
[![License](https://img.shields.io/github/license/philiprehberger/rb-hex)](LICENSE)

Hex encoding, decoding, and dump formatting for binary data

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem 'philiprehberger-hex'
```

Or install directly:

```bash
gem install philiprehberger-hex
```

## Usage

```ruby
require 'philiprehberger/hex'

Philiprehberger::Hex.encode('hello')     # => "68656c6c6f"
Philiprehberger::Hex.decode('68656c6c6f') # => "hello"
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

## API

| Method | Description |
|--------|-------------|
| `Hex.encode(str)` | Encode a string to hexadecimal |
| `Hex.decode(hex)` | Decode a hexadecimal string to binary |
| `Hex.dump(str)` | Produce an xxd-style hex dump |
| `Hex.format(str, group:)` | Format hex output with configurable grouping |
| `Hex.valid?(str)` | Check if a string is valid hexadecimal |

## Development

```bash
bundle install
bundle exec rspec      # Run tests
bundle exec rubocop    # Check code style
```

## License

MIT
