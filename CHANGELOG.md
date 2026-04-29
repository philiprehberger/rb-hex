# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this gem adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.7.0] - 2026-04-29

### Added
- `Hex.zeros(bytes)` and `Hex.ones(bytes)` to generate constant-byte hex strings (test fixtures, padding, bitmask construction)

## [0.6.0] - 2026-04-16

### Added
- `Hex.to_binary_string(hex, group:)` to convert a hex string to a binary digit string, with optional bit grouping
- `Hex.from_binary_string(binary)` to convert a binary digit string back to lowercase hex

## [0.5.0] - 2026-04-15

### Added
- `Hex.byte_length(hex)` to return the decoded byte count after normalising prefix and whitespace, without decoding

## [0.4.0] - 2026-04-14

### Added
- `Hex.from_bytes(bytes)` to build a hex string from an array of byte integers
- `Hex.normalize(hex, uppercase:)` to strip prefix, whitespace, and separators and return canonical hex
- `Hex.secure_equal?(hex1, hex2)` for constant-time hex comparison (MAC/HMAC safe)
- `Hex.chunk(hex, size:)` to split a hex string into byte-aligned chunks
- `Hex.and(hex1, hex2)`, `Hex.or(hex1, hex2)`, `Hex.not(hex)` bitwise operations

## [0.3.0] - 2026-04-03

### Added
- `Hex.encode` now accepts `prefix:` and `uppercase:` options for `0x` prefix and uppercase output
- `Hex.decode` now auto-strips `0x`/`0X` prefix before decoding
- `Hex.extract_range(hex, offset:, length:)` to extract byte ranges from hex strings
- `Hex.swap_endian(hex)` to reverse byte order
- `Hex.pad(hex, length:, side:)` to pad hex strings to target byte length
- `Hex.to_int(hex)` to convert hex strings to integers
- `Hex.from_int(int, bytes:)` to convert integers to hex strings

## [0.2.0] - 2026-04-01

### Added
- `Hex.bytes_from(hex)` to convert hex string to integer byte array
- `Hex.compare(hex1, hex2)` to find byte-level differences between hex strings
- `Hex.xor(hex1, hex2)` to XOR two hex strings
- `Hex.random(n)` to generate random hex strings

### Fixed
- Fix Support section formatting to match template

## [0.1.5] - 2026-03-31

### Added
- Add GitHub issue templates, dependabot config, and PR template

## [0.1.4] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.1.3] - 2026-03-24

### Fixed

- Standardize README code examples to use double-quote require statements
- Remove inline comments from Development section to match template

## [0.1.2] - 2026-03-24

### Fixed

- Fix Installation section quote style to double quotes

## [0.1.1] - 2026-03-22

### Changed

- Expand test coverage to 30+ examples with encode/decode roundtrips, binary data, boundary bytes, uppercase/lowercase handling, prefix rejection, and format edge cases

## [0.1.0] - 2026-03-22

### Added

- Initial release
- Hex encoding and decoding
- xxd-style hex dump output
- Configurable hex grouping format
- Hex string validation
