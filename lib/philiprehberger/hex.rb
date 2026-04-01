# frozen_string_literal: true

require_relative 'hex/version'
require 'securerandom'

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
    # @return [String] hex-encoded string
    def self.encode(str)
      validate_string!(str)
      str.unpack1('H*')
    end

    # Decode a hexadecimal string to binary
    #
    # @param hex [String] hex-encoded string
    # @return [String] decoded binary string
    def self.decode(hex)
      validate_string!(hex)
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
  end
end
