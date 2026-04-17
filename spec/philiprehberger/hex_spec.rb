# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::Hex do
  it 'has a version number' do
    expect(described_class::VERSION).not_to be_nil
  end

  describe '.encode' do
    it 'encodes a simple string' do
      expect(described_class.encode('hello')).to eq('68656c6c6f')
    end

    it 'encodes an empty string' do
      expect(described_class.encode('')).to eq('')
    end

    it 'encodes binary data' do
      expect(described_class.encode("\x00\xff")).to eq('00ff')
    end

    it 'raises Error for non-string' do
      expect { described_class.encode(123) }.to raise_error(described_class::Error)
    end

    it 'adds 0x prefix when requested' do
      expect(described_class.encode('hello', prefix: true)).to eq('0x68656c6c6f')
    end

    it 'produces uppercase output when requested' do
      expect(described_class.encode('hello', uppercase: true)).to eq('68656C6C6F')
    end

    it 'combines prefix and uppercase' do
      expect(described_class.encode("\xff", prefix: true, uppercase: true)).to eq('0xFF')
    end

    it 'returns empty string with prefix false for empty input' do
      expect(described_class.encode('', prefix: false)).to eq('')
    end

    it 'returns 0x prefix for empty input when requested' do
      expect(described_class.encode('', prefix: true)).to eq('0x')
    end
  end

  describe '.decode' do
    it 'decodes a hex string' do
      expect(described_class.decode('68656c6c6f')).to eq('hello')
    end

    it 'raises Error for empty string' do
      expect { described_class.decode('') }.to raise_error(described_class::Error)
    end

    it 'handles uppercase hex' do
      expect(described_class.decode('48454C4C4F')).to eq('HELLO')
    end

    it 'raises Error for odd-length hex' do
      expect { described_class.decode('abc') }.to raise_error(described_class::Error, /odd length/)
    end

    it 'raises Error for invalid hex characters' do
      expect { described_class.decode('zzzz') }.to raise_error(described_class::Error, /non-hex/)
    end

    it 'auto-strips 0x prefix' do
      expect(described_class.decode('0x68656c6c6f')).to eq('hello')
    end

    it 'auto-strips 0X prefix' do
      expect(described_class.decode('0X48454C4C4F')).to eq('HELLO')
    end

    it 'decodes 0x-prefixed uppercase hex' do
      expect(described_class.decode('0xFF').bytes).to eq([255])
    end
  end

  describe '.dump' do
    it 'produces xxd-style output' do
      result = described_class.dump('hello')
      expect(result).to include('00000000:')
      expect(result).to include('hello')
    end

    it 'handles empty string' do
      expect(described_class.dump('')).to eq('')
    end

    it 'handles multi-line dump' do
      str = 'a' * 32
      result = described_class.dump(str)
      expect(result.lines.length).to eq(2)
    end

    it 'replaces non-printable characters with dots' do
      result = described_class.dump("\x00\x01\x02")
      expect(result).to include('...')
    end
  end

  describe '.format' do
    it 'groups hex bytes' do
      result = described_class.format('hello', group: 2)
      expect(result).to eq('6865 6c6c 6f')
    end

    it 'uses custom group size' do
      result = described_class.format('hello', group: 1)
      expect(result).to eq('68 65 6c 6c 6f')
    end

    it 'handles empty string' do
      expect(described_class.format('')).to eq('')
    end
  end

  describe '.valid?' do
    it 'returns true for valid hex' do
      expect(described_class.valid?('abcdef0123456789')).to be true
    end

    it 'returns true for uppercase hex' do
      expect(described_class.valid?('ABCDEF')).to be true
    end

    it 'returns false for non-hex characters' do
      expect(described_class.valid?('xyz')).to be false
    end

    it 'returns false for empty string' do
      expect(described_class.valid?('')).to be false
    end

    it 'returns false for non-string' do
      expect(described_class.valid?(123)).to be false
    end

    it 'returns true for mixed case hex' do
      expect(described_class.valid?('aAbBcC')).to be true
    end

    it 'returns false for hex with spaces' do
      expect(described_class.valid?('ab cd')).to be false
    end

    it 'returns true for single hex digit' do
      expect(described_class.valid?('f')).to be true
    end
  end

  describe 'encode/decode roundtrip' do
    it 'roundtrips ASCII text' do
      original = 'Hello, World!'
      expect(described_class.decode(described_class.encode(original))).to eq(original)
    end

    it 'roundtrips empty string' do
      encoded = described_class.encode('')
      expect(encoded).to eq('')
    end

    it 'roundtrips binary data with null bytes' do
      original = "\x00\x01\x02\x03"
      decoded = described_class.decode(described_class.encode(original))
      expect(decoded.bytes).to eq(original.bytes)
    end

    it 'roundtrips all zero bytes' do
      original = "\x00" * 8
      decoded = described_class.decode(described_class.encode(original))
      expect(decoded.bytes).to eq([0] * 8)
    end

    it 'roundtrips all FF bytes' do
      original = "\xff" * 4
      decoded = described_class.decode(described_class.encode(original))
      expect(decoded.bytes).to eq([255] * 4)
    end

    it 'roundtrips a single byte' do
      original = "\x42"
      expect(described_class.decode(described_class.encode(original))).to eq(original)
    end
  end

  describe '.encode edge cases' do
    it 'produces lowercase hex output' do
      result = described_class.encode("\xff")
      expect(result).to eq('ff')
      expect(result).to match(/\A[0-9a-f]+\z/)
    end

    it 'encodes long strings' do
      long_str = 'x' * 10_000
      encoded = described_class.encode(long_str)
      expect(encoded.length).to eq(20_000)
    end
  end

  describe '.decode edge cases' do
    it 'decodes uppercase hex input' do
      expect(described_class.decode('FF').bytes).to eq([255])
    end

    it 'decodes mixed case hex input' do
      expect(described_class.decode('fF').bytes).to eq([255])
    end

    it 'raises Error for non-string input' do
      expect { described_class.decode(123) }.to raise_error(described_class::Error)
    end

    it 'auto-strips 0x prefix in edge case' do
      expect(described_class.decode('0x00ff').bytes).to eq([0, 255])
    end

    it 'raises Error for single character' do
      expect { described_class.decode('a') }.to raise_error(described_class::Error, /odd length/)
    end
  end

  describe '.dump edge cases' do
    it 'shows printable ASCII in text column' do
      result = described_class.dump('ABC')
      expect(result).to include('ABC')
    end

    it 'raises Error for non-string' do
      expect { described_class.dump(123) }.to raise_error(described_class::Error)
    end
  end

  describe '.format edge cases' do
    it 'uses default group size of 2' do
      result = described_class.format('AB')
      expect(result).to be_a(String)
      expect(result).to include('41')
    end

    it 'handles large group size' do
      result = described_class.format('hello', group: 100)
      expect(result).to eq('68656c6c6f')
    end

    it 'raises Error for non-string' do
      expect { described_class.format(42) }.to raise_error(described_class::Error)
    end
  end

  describe '.bytes_from' do
    it 'converts hex to byte array' do
      expect(described_class.bytes_from('48656c6c6f')).to eq([0x48, 0x65, 0x6c, 0x6c, 0x6f])
    end

    it 'handles single byte' do
      expect(described_class.bytes_from('ff')).to eq([255])
    end

    it 'handles all zeros' do
      expect(described_class.bytes_from('0000')).to eq([0, 0])
    end

    it 'raises Error for odd-length hex' do
      expect { described_class.bytes_from('abc') }.to raise_error(described_class::Error, /odd length/)
    end

    it 'raises Error for invalid hex' do
      expect { described_class.bytes_from('zzzz') }.to raise_error(described_class::Error, /non-hex/)
    end

    it 'raises Error for non-string' do
      expect { described_class.bytes_from(123) }.to raise_error(described_class::Error)
    end
  end

  describe '.compare' do
    it 'returns empty array for identical hex strings' do
      expect(described_class.compare('aabb', 'aabb')).to eq([])
    end

    it 'returns differences' do
      diffs = described_class.compare('aabb', 'aacc')
      expect(diffs.length).to eq(1)
      expect(diffs[0][:offset]).to eq(1)
      expect(diffs[0][:expected]).to eq('bb')
      expect(diffs[0][:actual]).to eq('cc')
    end

    it 'handles different lengths' do
      diffs = described_class.compare('aabb', 'aa')
      expect(diffs.length).to eq(1)
      expect(diffs[0][:offset]).to eq(1)
      expect(diffs[0][:expected]).to eq('bb')
      expect(diffs[0][:actual]).to be_nil
    end

    it 'detects all differing bytes' do
      diffs = described_class.compare('0102', 'ff03')
      expect(diffs.length).to eq(2)
    end
  end

  describe '.xor' do
    it 'XORs two hex strings' do
      expect(described_class.xor('ff00', '0f0f')).to eq('f00f')
    end

    it 'XOR with itself produces zeros' do
      expect(described_class.xor('abcd', 'abcd')).to eq('0000')
    end

    it 'XOR with zeros is identity' do
      expect(described_class.xor('abcd', '0000')).to eq('abcd')
    end

    it 'raises Error for different lengths' do
      expect { described_class.xor('aabb', 'aa') }.to raise_error(described_class::Error, /same length/)
    end
  end

  describe '.random' do
    it 'generates hex string of correct length' do
      result = described_class.random(8)
      expect(result.length).to eq(16)
    end

    it 'generates valid hex' do
      result = described_class.random(4)
      expect(described_class.valid?(result)).to be true
    end

    it 'raises Error for non-positive count' do
      expect { described_class.random(0) }.to raise_error(described_class::Error)
      expect { described_class.random(-1) }.to raise_error(described_class::Error)
    end

    it 'generates different values on each call' do
      results = Array.new(10) { described_class.random(16) }
      expect(results.uniq.length).to eq(10)
    end
  end

  describe '.extract_range' do
    it 'extracts bytes from the beginning' do
      expect(described_class.extract_range('aabbccdd', offset: 0, length: 2)).to eq('aabb')
    end

    it 'extracts bytes from the middle' do
      expect(described_class.extract_range('aabbccdd', offset: 1, length: 2)).to eq('bbcc')
    end

    it 'extracts bytes from the end' do
      expect(described_class.extract_range('aabbccdd', offset: 2, length: 2)).to eq('ccdd')
    end

    it 'extracts a single byte' do
      expect(described_class.extract_range('aabbcc', offset: 1, length: 1)).to eq('bb')
    end

    it 'strips 0x prefix before extracting' do
      expect(described_class.extract_range('0xaabbccdd', offset: 0, length: 2)).to eq('aabb')
    end

    it 'raises Error for offset out of range' do
      expect { described_class.extract_range('aabb', offset: 2, length: 1) }.to raise_error(described_class::Error, /offset/)
    end

    it 'raises Error for negative offset' do
      expect { described_class.extract_range('aabb', offset: -1, length: 1) }.to raise_error(described_class::Error, /offset/)
    end

    it 'raises Error for length exceeding data' do
      expect { described_class.extract_range('aabb', offset: 0, length: 3) }.to raise_error(described_class::Error, /length/)
    end

    it 'raises Error for odd-length hex' do
      expect { described_class.extract_range('aab', offset: 0, length: 1) }.to raise_error(described_class::Error, /odd length/)
    end

    it 'raises Error for invalid hex' do
      expect { described_class.extract_range('zzzz', offset: 0, length: 1) }.to raise_error(described_class::Error, /non-hex/)
    end
  end

  describe '.swap_endian' do
    it 'swaps two bytes' do
      expect(described_class.swap_endian('aabb')).to eq('bbaa')
    end

    it 'swaps three bytes' do
      expect(described_class.swap_endian('aabbcc')).to eq('ccbbaa')
    end

    it 'swaps four bytes' do
      expect(described_class.swap_endian('01020304')).to eq('04030201')
    end

    it 'returns same for single byte' do
      expect(described_class.swap_endian('ff')).to eq('ff')
    end

    it 'strips 0x prefix before swapping' do
      expect(described_class.swap_endian('0xaabb')).to eq('bbaa')
    end

    it 'raises Error for odd-length hex' do
      expect { described_class.swap_endian('aab') }.to raise_error(described_class::Error, /odd length/)
    end

    it 'raises Error for invalid hex' do
      expect { described_class.swap_endian('zzzz') }.to raise_error(described_class::Error, /non-hex/)
    end
  end

  describe '.pad' do
    it 'left-pads to target byte length' do
      expect(described_class.pad('ff', length: 4)).to eq('000000ff')
    end

    it 'right-pads to target byte length' do
      expect(described_class.pad('ff', length: 4, side: :right)).to eq('ff000000')
    end

    it 'returns unchanged if already at target length' do
      expect(described_class.pad('aabb', length: 2)).to eq('aabb')
    end

    it 'returns unchanged if longer than target length' do
      expect(described_class.pad('aabbcc', length: 2)).to eq('aabbcc')
    end

    it 'pads empty-ish two-char hex' do
      expect(described_class.pad('00', length: 3)).to eq('000000')
    end

    it 'strips 0x prefix before padding' do
      expect(described_class.pad('0xff', length: 4)).to eq('000000ff')
    end

    it 'raises Error for invalid side' do
      expect { described_class.pad('ff', length: 2, side: :center) }.to raise_error(described_class::Error, /side/)
    end

    it 'raises Error for odd-length hex' do
      expect { described_class.pad('f', length: 2) }.to raise_error(described_class::Error, /odd length/)
    end

    it 'raises Error for invalid hex' do
      expect { described_class.pad('zz', length: 2) }.to raise_error(described_class::Error, /non-hex/)
    end
  end

  describe '.to_int' do
    it 'converts hex to integer' do
      expect(described_class.to_int('ff')).to eq(255)
    end

    it 'converts multi-byte hex' do
      expect(described_class.to_int('0100')).to eq(256)
    end

    it 'handles leading zeros' do
      expect(described_class.to_int('00ff')).to eq(255)
    end

    it 'strips 0x prefix' do
      expect(described_class.to_int('0xff')).to eq(255)
    end

    it 'strips 0X prefix' do
      expect(described_class.to_int('0XFF')).to eq(255)
    end

    it 'converts zero' do
      expect(described_class.to_int('00')).to eq(0)
    end

    it 'raises Error for empty string after strip' do
      expect { described_class.to_int('') }.to raise_error(described_class::Error, /empty/)
    end

    it 'raises Error for invalid hex' do
      expect { described_class.to_int('zz') }.to raise_error(described_class::Error, /non-hex/)
    end

    it 'raises Error for non-string' do
      expect { described_class.to_int(123) }.to raise_error(described_class::Error)
    end
  end

  describe '.from_int' do
    it 'converts integer to hex' do
      expect(described_class.from_int(255)).to eq('ff')
    end

    it 'converts zero' do
      expect(described_class.from_int(0)).to eq('00')
    end

    it 'pads to byte count' do
      expect(described_class.from_int(255, bytes: 4)).to eq('000000ff')
    end

    it 'converts large integer' do
      expect(described_class.from_int(65_535)).to eq('ffff')
    end

    it 'ensures even-length output' do
      expect(described_class.from_int(1)).to eq('01')
    end

    it 'does not truncate if value exceeds byte count' do
      expect(described_class.from_int(65_535, bytes: 1)).to eq('ffff')
    end

    it 'raises Error for non-integer' do
      expect { described_class.from_int('ff') }.to raise_error(described_class::Error, /Integer/)
    end

    it 'raises Error for negative integer' do
      expect { described_class.from_int(-1) }.to raise_error(described_class::Error, /non-negative/)
    end
  end

  describe 'encode/decode roundtrip with prefix' do
    it 'roundtrips with 0x prefix' do
      original = 'hello'
      encoded = described_class.encode(original, prefix: true)
      expect(described_class.decode(encoded)).to eq(original)
    end

    it 'roundtrips with uppercase and prefix' do
      original = "\xde\xad\xbe\xef"
      encoded = described_class.encode(original, prefix: true, uppercase: true)
      expect(described_class.decode(encoded).bytes).to eq(original.bytes)
    end
  end

  describe 'to_int/from_int roundtrip' do
    it 'roundtrips through integer' do
      hex = 'deadbeef'
      expect(described_class.from_int(described_class.to_int(hex))).to eq(hex)
    end

    it 'roundtrips with padding' do
      expect(described_class.from_int(described_class.to_int('00ff'), bytes: 2)).to eq('00ff')
    end
  end

  describe '.from_bytes' do
    it 'builds hex from byte array' do
      expect(described_class.from_bytes([0x48, 0x65, 0x6c, 0x6c, 0x6f])).to eq('48656c6c6f')
    end

    it 'handles empty array' do
      expect(described_class.from_bytes([])).to eq('')
    end

    it 'handles single byte' do
      expect(described_class.from_bytes([255])).to eq('ff')
    end

    it 'handles all zeros' do
      expect(described_class.from_bytes([0, 0, 0])).to eq('000000')
    end

    it 'roundtrips through bytes_from' do
      hex = 'deadbeef'
      expect(described_class.from_bytes(described_class.bytes_from(hex))).to eq(hex)
    end

    it 'raises Error for non-array' do
      expect { described_class.from_bytes('ff') }.to raise_error(described_class::Error, /Array/)
    end

    it 'raises Error for non-integer elements' do
      expect { described_class.from_bytes([1, 'x']) }.to raise_error(described_class::Error)
    end

    it 'raises Error for out-of-range byte' do
      expect { described_class.from_bytes([256]) }.to raise_error(described_class::Error)
    end

    it 'raises Error for negative byte' do
      expect { described_class.from_bytes([-1]) }.to raise_error(described_class::Error)
    end
  end

  describe '.normalize' do
    it 'strips 0x prefix' do
      expect(described_class.normalize('0xaabb')).to eq('aabb')
    end

    it 'strips 0X prefix' do
      expect(described_class.normalize('0XAABB')).to eq('aabb')
    end

    it 'strips whitespace' do
      expect(described_class.normalize('aa bb  cc')).to eq('aabbcc')
    end

    it 'strips colon separators' do
      expect(described_class.normalize('aa:bb:cc')).to eq('aabbcc')
    end

    it 'strips dash separators' do
      expect(described_class.normalize('aa-bb-cc')).to eq('aabbcc')
    end

    it 'strips underscore separators' do
      expect(described_class.normalize('aa_bb_cc')).to eq('aabbcc')
    end

    it 'lowercases mixed case input' do
      expect(described_class.normalize('AaBbCc')).to eq('aabbcc')
    end

    it 'combines prefix, whitespace, separators, and case' do
      expect(described_class.normalize('0x AA:BB-CC_dd')).to eq('aabbccdd')
    end

    it 'returns uppercase when requested' do
      expect(described_class.normalize('aa:bb', uppercase: true)).to eq('AABB')
    end

    it 'raises Error for odd length after normalization' do
      expect { described_class.normalize('abc') }.to raise_error(described_class::Error, /odd length/)
    end

    it 'raises Error for non-hex characters' do
      expect { described_class.normalize('zzzz') }.to raise_error(described_class::Error, /non-hex/)
    end

    it 'raises Error for empty input after stripping' do
      expect { described_class.normalize('  ') }.to raise_error(described_class::Error, /empty/)
    end

    it 'raises Error for non-string' do
      expect { described_class.normalize(123) }.to raise_error(described_class::Error)
    end
  end

  describe '.byte_length' do
    it 'returns byte count for plain hex' do
      expect(described_class.byte_length('aabbcc')).to eq(3)
    end

    it 'returns byte count for hex with 0x prefix' do
      expect(described_class.byte_length('0xaabbcc')).to eq(3)
    end

    it 'returns byte count for hex with 0X prefix' do
      expect(described_class.byte_length('0XAABB')).to eq(2)
    end

    it 'returns byte count for uppercase hex' do
      expect(described_class.byte_length('DEADBEEF')).to eq(4)
    end

    it 'strips whitespace before counting' do
      expect(described_class.byte_length('aa bb  cc')).to eq(3)
    end

    it 'strips colon separators before counting' do
      expect(described_class.byte_length('aa:bb:cc')).to eq(3)
    end

    it 'strips dash separators before counting' do
      expect(described_class.byte_length('aa-bb-cc')).to eq(3)
    end

    it 'strips underscore separators before counting' do
      expect(described_class.byte_length('aa_bb_cc')).to eq(3)
    end

    it 'handles combined prefix, separators, and case' do
      expect(described_class.byte_length('0x AA:BB-CC_dd')).to eq(4)
    end

    it 'returns 0 for empty string' do
      expect(described_class.byte_length('')).to eq(0)
    end

    it 'raises Error for odd-length hex' do
      expect { described_class.byte_length('abc') }.to raise_error(described_class::Error, /odd length/)
    end

    it 'raises Error for invalid hex characters' do
      expect { described_class.byte_length('zzzz') }.to raise_error(described_class::Error, /non-hex/)
    end

    it 'raises Error for non-string' do
      expect { described_class.byte_length(123) }.to raise_error(described_class::Error)
    end
  end

  describe '.secure_equal?' do
    it 'returns true for identical hex' do
      expect(described_class.secure_equal?('aabb', 'aabb')).to be true
    end

    it 'returns true for case-insensitive equal hex' do
      expect(described_class.secure_equal?('aabb', 'AABB')).to be true
    end

    it 'returns false for different hex' do
      expect(described_class.secure_equal?('aabb', 'aacc')).to be false
    end

    it 'returns false for different lengths' do
      expect(described_class.secure_equal?('aa', 'aabb')).to be false
    end

    it 'handles 0x prefixes transparently' do
      expect(described_class.secure_equal?('0xaabb', 'aabb')).to be true
    end

    it 'raises Error for non-string first arg' do
      expect { described_class.secure_equal?(123, 'ff') }.to raise_error(described_class::Error)
    end

    it 'raises Error for non-string second arg' do
      expect { described_class.secure_equal?('ff', 123) }.to raise_error(described_class::Error)
    end
  end

  describe '.chunk' do
    it 'splits into 2-byte chunks' do
      expect(described_class.chunk('aabbccdd', size: 2)).to eq(%w[aabb ccdd])
    end

    it 'splits into 1-byte chunks' do
      expect(described_class.chunk('aabbcc', size: 1)).to eq(%w[aa bb cc])
    end

    it 'returns last chunk shorter than size when not aligned' do
      expect(described_class.chunk('aabbccddee', size: 2)).to eq(%w[aabb ccdd ee])
    end

    it 'returns empty array for empty hex' do
      expect(described_class.chunk('', size: 2)).to eq([])
    end

    it 'strips 0x prefix before chunking' do
      expect(described_class.chunk('0xaabbccdd', size: 2)).to eq(%w[aabb ccdd])
    end

    it 'raises Error for non-positive size' do
      expect { described_class.chunk('aabb', size: 0) }.to raise_error(described_class::Error, /size/)
      expect { described_class.chunk('aabb', size: -1) }.to raise_error(described_class::Error, /size/)
    end

    it 'raises Error for non-integer size' do
      expect { described_class.chunk('aabb', size: 2.5) }.to raise_error(described_class::Error, /size/)
    end

    it 'raises Error for odd-length hex' do
      expect { described_class.chunk('aab', size: 1) }.to raise_error(described_class::Error, /odd length/)
    end

    it 'raises Error for invalid hex' do
      expect { described_class.chunk('zzzz', size: 1) }.to raise_error(described_class::Error, /non-hex/)
    end
  end

  describe '.and' do
    it 'ANDs two hex strings' do
      expect(described_class.and('ff00', '0f0f')).to eq('0f00')
    end

    it 'AND with itself is identity' do
      expect(described_class.and('abcd', 'abcd')).to eq('abcd')
    end

    it 'AND with zeros is zero' do
      expect(described_class.and('abcd', '0000')).to eq('0000')
    end

    it 'raises Error for different lengths' do
      expect { described_class.and('aabb', 'aa') }.to raise_error(described_class::Error, /same length/)
    end
  end

  describe '.or' do
    it 'ORs two hex strings' do
      expect(described_class.or('ff00', '0f0f')).to eq('ff0f')
    end

    it 'OR with zeros is identity' do
      expect(described_class.or('abcd', '0000')).to eq('abcd')
    end

    it 'OR with all ones is all ones' do
      expect(described_class.or('abcd', 'ffff')).to eq('ffff')
    end

    it 'raises Error for different lengths' do
      expect { described_class.or('aabb', 'aa') }.to raise_error(described_class::Error, /same length/)
    end
  end

  describe '.not' do
    it 'inverts bits' do
      expect(described_class.not('ff00')).to eq('00ff')
    end

    it 'inverts mixed bits' do
      expect(described_class.not('a5')).to eq('5a')
    end

    it 'applied twice returns original' do
      original = 'deadbeef'
      expect(described_class.not(described_class.not(original))).to eq(original)
    end

    it 'raises Error for invalid hex' do
      expect { described_class.not('zz') }.to raise_error(described_class::Error)
    end
  end

  describe '.to_binary_string' do
    it 'converts a single byte to 8-bit binary string' do
      expect(described_class.to_binary_string('ff')).to eq('11111111')
    end

    it 'zero-pads bytes to 8 bits' do
      expect(described_class.to_binary_string('01')).to eq('00000001')
    end

    it 'converts multiple bytes' do
      expect(described_class.to_binary_string('aabb')).to eq('1010101010111011')
    end

    it 'groups bits by N with spaces' do
      expect(described_class.to_binary_string('aabb', group: 4)).to eq('1010 1010 1011 1011')
    end

    it 'groups bits by 8' do
      expect(described_class.to_binary_string('aabb', group: 8)).to eq('10101010 10111011')
    end

    it 'strips 0x prefix before converting' do
      expect(described_class.to_binary_string('0xaabb')).to eq('1010101010111011')
    end

    it 'strips 0X prefix before converting' do
      expect(described_class.to_binary_string('0XFF')).to eq('11111111')
    end

    it 'converts 00 to eight zeros' do
      expect(described_class.to_binary_string('00')).to eq('00000000')
    end

    it 'raises Error for odd-length hex' do
      expect { described_class.to_binary_string('abc') }.to raise_error(described_class::Error, /odd length/)
    end

    it 'raises Error for invalid hex characters' do
      expect { described_class.to_binary_string('zz') }.to raise_error(described_class::Error, /non-hex/)
    end

    it 'raises Error for non-string input' do
      expect { described_class.to_binary_string(123) }.to raise_error(described_class::Error)
    end
  end

  describe '.from_binary_string' do
    it 'converts an 8-bit binary string to hex' do
      expect(described_class.from_binary_string('11111111')).to eq('ff')
    end

    it 'converts multiple bytes' do
      expect(described_class.from_binary_string('1010101010111011')).to eq('aabb')
    end

    it 'strips whitespace before converting' do
      expect(described_class.from_binary_string('1010 1010 1011 1011')).to eq('aabb')
    end

    it 'zero-pads to a multiple of 8 bits' do
      expect(described_class.from_binary_string('1')).to eq('01')
    end

    it 'handles all zeros' do
      expect(described_class.from_binary_string('00000000')).to eq('00')
    end

    it 'raises Error for non-binary characters' do
      expect { described_class.from_binary_string('10201010') }.to raise_error(described_class::Error, /only 0 and 1/)
    end

    it 'raises Error for empty string after stripping whitespace' do
      expect { described_class.from_binary_string('   ') }.to raise_error(described_class::Error, /empty/)
    end

    it 'raises Error for non-string input' do
      expect { described_class.from_binary_string(123) }.to raise_error(described_class::Error)
    end
  end

  describe 'to_binary_string/from_binary_string roundtrip' do
    it 'roundtrips a hex string through binary' do
      hex = 'deadbeef'
      expect(described_class.from_binary_string(described_class.to_binary_string(hex))).to eq(hex)
    end

    it 'roundtrips with grouping' do
      hex = 'aabb'
      binary = described_class.to_binary_string(hex, group: 4)
      expect(described_class.from_binary_string(binary)).to eq(hex)
    end
  end
end
