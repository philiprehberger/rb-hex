# frozen_string_literal: true

require_relative 'hex/version'
require 'securerandom'
require 'openssl'

module Philiprehberger
  module Hex
    class Error < StandardError; end

    HEX_PATTERN = /\A[0-9a-fA-F]*\z/

    def self.validate_string!(str)
      raise Error, 'expected a String' unless str.is_a?(String)
    end

    private_class_method :validate_string!

    # Encode a string to hexadecimal
    #
    # @param str [String]
    # @param prefix [Boolean] prepend "0x" prefix
    # @param uppercase [Boolean] use uppercase hex characters
    # @return [String] hex-encoded string
    def self.encode(str, prefix: false, uppercase: false)
      validate_string!(str)
      hex = str.unpack1('H*')
      hex = hex.upcase if uppercase
      prefix ? "0x#{hex}" : hex
    end

    # Decode a hexadecimal string to binary
    # Automatically strips 0x/0X prefix if present
    #
    # @param hex [String] hex-encoded string
    # @return [String] decoded binary string
    def self.decode(hex)
      validate_string!(hex)
      hex = strip_prefix(hex)
      raise Error, 'invalid hex string: odd length' if hex.length.odd?
      raise Error, 'invalid hex string: non-hex characters' unless valid?(hex)

      [hex].pack('H*')
    end

    # Produce an xxd-style hex dump
    #
    # @param str [String]
    # @return [String] formatted hex dump
    def self.dump(str)
      validate_string!(str)
      lines = []
      bytes = str.bytes

      bytes.each_slice(16).with_index do |chunk, index|
        offset = Kernel.format('%08x', index * 16)
        hex_part = chunk.each_slice(2).map { |pair| pair.map { |b| Kernel.format('%02x', b) }.join }.join(' ')
        ascii_part = chunk.map { |b| b.between?(32, 126) ? b.chr : '.' }.join
        lines << Kernel.format('%-10s %-40s %s', "#{offset}:", hex_part, ascii_part)
      end

      lines.join("\n")
    end

    # Format a string as grouped hex
    #
    # @param str [String]
    # @param group [Integer] number of bytes per group
    # @return [String] grouped hex string
    def self.format(str, group: 2)
      validate_string!(str)
      hex = encode(str)
      hex.scan(/.{1,#{group * 2}}/).join(' ')
    end

    # Check if a string is valid hexadecimal
    #
    # @param str [String]
    # @return [Boolean]
    def self.valid?(str)
      return false unless str.is_a?(String)
      return false if str.empty?

      HEX_PATTERN.match?(str)
    end

    # Convert a hex string to an array of integer byte values
    #
    # @param hex [String] hex-encoded string (even length)
    # @return [Array<Integer>] array of byte values
    def self.bytes_from(hex)
      validate_string!(hex)
      raise Error, 'invalid hex string: odd length' if hex.length.odd?
      raise Error, 'invalid hex string: non-hex characters' unless valid?(hex)

      [hex].pack('H*').bytes
    end

    # Compare two hex strings and return byte-level differences
    #
    # @param hex1 [String] first hex string
    # @param hex2 [String] second hex string
    # @return [Array<Hash>] array of { offset:, expected:, actual: } for differing bytes
    def self.compare(hex1, hex2)
      bytes1 = bytes_from(hex1)
      bytes2 = bytes_from(hex2)

      max_len = [bytes1.length, bytes2.length].max
      diffs = []

      max_len.times do |i|
        b1 = bytes1[i]
        b2 = bytes2[i]
        next if b1 == b2

        diffs << {
          offset: i,
          expected: b1 ? Kernel.format('%02x', b1) : nil,
          actual: b2 ? Kernel.format('%02x', b2) : nil
        }
      end

      diffs
    end

    # XOR two hex strings and return the hex result
    #
    # @param hex1 [String] first hex string
    # @param hex2 [String] second hex string
    # @return [String] hex-encoded XOR result
    def self.xor(hex1, hex2)
      bytes1 = bytes_from(hex1)
      bytes2 = bytes_from(hex2)
      raise Error, 'hex strings must be the same length' unless bytes1.length == bytes2.length

      bytes1.zip(bytes2).map { |a, b| Kernel.format('%02x', a ^ b) }.join
    end

    # Generate a random hex string of n bytes
    #
    # @param n [Integer] number of random bytes
    # @return [String] hex-encoded random string (2*n characters)
    def self.random(n)
      raise Error, 'byte count must be positive' unless n.is_a?(Integer) && n.positive?

      SecureRandom.hex(n)
    end

    # Hex string of `bytes` zero bytes ('00' * bytes).
    #
    # @param bytes [Integer] non-negative byte count
    # @return [String] lowercase hex
    # @raise [ArgumentError] when bytes is negative
    def self.zeros(bytes)
      raise ArgumentError, 'bytes must be non-negative' if bytes.negative?

      '00' * bytes
    end

    # Hex string of `bytes` all-ones bytes ('ff' * bytes).
    #
    # @param bytes [Integer] non-negative byte count
    # @return [String] lowercase hex
    # @raise [ArgumentError] when bytes is negative
    def self.ones(bytes)
      raise ArgumentError, 'bytes must be non-negative' if bytes.negative?

      'ff' * bytes
    end

    # Extract a range of bytes from a hex string
    #
    # @param hex [String] hex-encoded string
    # @param offset [Integer] byte offset to start from
    # @param length [Integer] number of bytes to extract
    # @return [String] hex substring
    def self.extract_range(hex, offset:, length:)
      validate_string!(hex)
      hex = strip_prefix(hex)
      raise Error, 'invalid hex string: odd length' if hex.length.odd?
      raise Error, 'invalid hex string: non-hex characters' unless valid?(hex)

      total_bytes = hex.length / 2
      raise Error, 'offset out of range' if offset.negative? || offset >= total_bytes
      raise Error, 'length out of range' if length.negative? || (offset + length) > total_bytes

      hex[offset * 2, length * 2]
    end

    # Reverse byte order of a hex string
    #
    # @param hex [String] hex-encoded string (even length)
    # @return [String] hex string with reversed byte order
    def self.swap_endian(hex)
      validate_string!(hex)
      hex = strip_prefix(hex)
      raise Error, 'invalid hex string: odd length' if hex.length.odd?
      raise Error, 'invalid hex string: non-hex characters' unless valid?(hex)

      hex.scan(/../).reverse.join
    end

    # Pad a hex string to a target byte length with zeros
    #
    # @param hex [String] hex-encoded string
    # @param length [Integer] target byte length
    # @param side [Symbol] :left or :right
    # @return [String] padded hex string
    def self.pad(hex, length:, side: :left)
      validate_string!(hex)
      hex = strip_prefix(hex)
      raise Error, 'invalid hex string: odd length' if hex.length.odd?
      raise Error, 'invalid hex string: non-hex characters' unless valid?(hex)
      raise Error, 'side must be :left or :right' unless %i[left right].include?(side)

      target_chars = length * 2
      return hex if hex.length >= target_chars

      padding = '0' * (target_chars - hex.length)
      side == :left ? "#{padding}#{hex}" : "#{hex}#{padding}"
    end

    # Convert a hex string to an integer
    #
    # @param hex [String] hex-encoded string
    # @return [Integer]
    def self.to_int(hex)
      validate_string!(hex)
      hex = strip_prefix(hex)
      raise Error, 'invalid hex string: empty' if hex.empty?
      raise Error, 'invalid hex string: non-hex characters' unless valid?(hex)

      hex.to_i(16)
    end

    # Convert an integer to a hex string
    #
    # @param int [Integer]
    # @param bytes [Integer, nil] optional zero-padded byte count
    # @return [String] hex-encoded string
    def self.from_int(int, bytes: nil)
      raise Error, 'expected an Integer' unless int.is_a?(Integer)
      raise Error, 'integer must be non-negative' if int.negative?

      hex = int.to_s(16)
      hex = "0#{hex}" if hex.length.odd?

      if bytes
        target = bytes * 2
        hex = hex.rjust(target, '0') if hex.length < target
      end

      hex
    end

    # Convert an array of byte integers (0..255) to a hex string
    #
    # @param bytes [Array<Integer>]
    # @return [String] lowercase hex
    def self.from_bytes(bytes)
      raise Error, 'expected an Array' unless bytes.is_a?(Array)
      unless bytes.all? { |b| b.is_a?(Integer) && b.between?(0, 255) }
        raise Error, 'all elements must be integers in 0..255'
      end

      bytes.pack('C*').unpack1('H*')
    end

    # Normalize a hex string by stripping prefix, whitespace, and separators
    # Validates that the result is even-length and purely hexadecimal
    #
    # @param hex [String]
    # @param uppercase [Boolean] return uppercase instead of lowercase
    # @return [String] canonical hex
    def self.normalize(hex, uppercase: false)
      validate_string!(hex)
      stripped = strip_prefix(hex).gsub(/[\s:\-_]/, '')
      raise Error, 'invalid hex string: odd length' if stripped.length.odd?
      raise Error, 'invalid hex string: empty' if stripped.empty?
      raise Error, 'invalid hex string: non-hex characters' unless valid?(stripped)

      uppercase ? stripped.upcase : stripped.downcase
    end

    # Return the decoded byte count of a hex string without decoding
    # Strips 0x/0X prefix and whitespace/separators before counting
    #
    # @param hex [String]
    # @return [Integer] number of bytes the hex would decode to
    def self.byte_length(hex)
      validate_string!(hex)
      cleaned = strip_prefix(hex).gsub(/[\s:\-_]/, '')
      raise Error, 'invalid hex string: odd length' if cleaned.length.odd?
      raise Error, 'invalid hex string: non-hex characters' unless cleaned.empty? || valid?(cleaned)

      cleaned.length / 2
    end

    # Constant-time hex comparison, safe for MAC/HMAC/signature checks
    # Comparison is case-insensitive; lengths must match (length is not secret)
    #
    # @param hex1 [String]
    # @param hex2 [String]
    # @return [Boolean]
    def self.secure_equal?(hex1, hex2)
      validate_string!(hex1)
      validate_string!(hex2)
      a = strip_prefix(hex1).downcase
      b = strip_prefix(hex2).downcase
      return false unless a.length == b.length

      OpenSSL.fixed_length_secure_compare(a, b)
    end

    # Split a hex string into an array of byte-aligned chunks
    # The last chunk may be shorter than size bytes if the input length is not a multiple
    #
    # @param hex [String]
    # @param size [Integer] bytes per chunk (>= 1)
    # @return [Array<String>]
    def self.chunk(hex, size:)
      validate_string!(hex)
      raise Error, 'size must be a positive integer' unless size.is_a?(Integer) && size.positive?

      stripped = strip_prefix(hex)
      raise Error, 'invalid hex string: odd length' if stripped.length.odd?
      raise Error, 'invalid hex string: non-hex characters' unless stripped.empty? || valid?(stripped)

      stripped.scan(/.{1,#{size * 2}}/)
    end

    # Bitwise AND of two equal-length hex strings
    #
    # @param hex1 [String]
    # @param hex2 [String]
    # @return [String] lowercase hex result
    def self.and(hex1, hex2)
      bitwise_binop(hex1, hex2) { |a, b| a & b }
    end

    # Bitwise OR of two equal-length hex strings
    #
    # @param hex1 [String]
    # @param hex2 [String]
    # @return [String] lowercase hex result
    def self.or(hex1, hex2)
      bitwise_binop(hex1, hex2) { |a, b| a | b }
    end

    # Bitwise NOT (one's complement) of a hex string
    #
    # @param hex [String]
    # @return [String] lowercase hex result
    def self.not(hex)
      bytes_from(hex).map { |b| Kernel.format('%02x', ~b & 0xFF) }.join
    end

    # Convert a hex string to a binary digit string
    # Each byte is always zero-padded to 8 bits
    # Strips 0x/0X prefix if present
    #
    # @param hex [String] hex-encoded string
    # @param group [Integer, nil] insert a space every N bits when given
    # @return [String] binary digit string
    def self.to_binary_string(hex, group: nil)
      validate_string!(hex)
      stripped = strip_prefix(hex)
      raise Error, 'invalid hex string: odd length' if stripped.length.odd?
      raise Error, 'invalid hex string: non-hex characters' unless stripped.empty? || valid?(stripped)

      bits = stripped.scan(/../).map { |byte| byte.to_i(16).to_s(2).rjust(8, '0') }.join
      return bits unless group

      bits.scan(/.{1,#{group}}/).join(' ')
    end

    # Convert a binary digit string to a lowercase hex string
    # Strips whitespace; zero-pads to a multiple of 8 bits if needed
    #
    # @param binary [String] binary digit string (may contain spaces)
    # @return [String] lowercase hex string
    def self.from_binary_string(binary)
      validate_string!(binary)
      stripped = binary.gsub(/\s/, '')
      raise Error, 'invalid binary string: must contain only 0 and 1' unless stripped.match?(/\A[01]*\z/)
      raise Error, 'invalid binary string: empty' if stripped.empty?

      padded = stripped.rjust((stripped.length + 7) / 8 * 8, '0')
      padded.scan(/.{8}/).map { |byte| byte.to_i(2).to_s(16).rjust(2, '0') }.join
    end

    # Strip 0x/0X prefix from a hex string
    #
    # @param hex [String]
    # @return [String]
    def self.strip_prefix(hex)
      hex.start_with?('0x', '0X') ? hex[2..] : hex
    end

    private_class_method :strip_prefix

    def self.bitwise_binop(hex1, hex2)
      bytes1 = bytes_from(hex1)
      bytes2 = bytes_from(hex2)
      raise Error, 'hex strings must be the same length' unless bytes1.length == bytes2.length

      bytes1.zip(bytes2).map { |a, b| Kernel.format('%02x', yield(a, b)) }.join
    end

    private_class_method :bitwise_binop
  end
end
