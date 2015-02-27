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
  end
end
