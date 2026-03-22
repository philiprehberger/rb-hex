# frozen_string_literal: true

require_relative 'hex/version'

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
        offset = format('%08x', index * 16)
        hex_part = chunk.each_slice(2).map { |pair| pair.map { |b| format('%02x', b) }.join }.join(' ')
        ascii_part = chunk.map { |b| b.between?(32, 126) ? b.chr : '.' }.join
        lines << format('%-10s %-40s %s', "#{offset}:", hex_part, ascii_part)
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
  end
end
