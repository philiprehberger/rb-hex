# frozen_string_literal: true

require_relative 'lib/philiprehberger/hex/version'

Gem::Specification.new do |spec|
  spec.name          = 'philiprehberger-hex'
  spec.version       = Philiprehberger::Hex::VERSION
  spec.authors       = ['Philip Rehberger']
  spec.email         = ['me@philiprehberger.com']

  spec.summary       = 'Hex encoding, decoding, and dump formatting for binary data'
  spec.description   = 'Encode and decode hexadecimal strings, produce xxd-style hex dumps, ' \
                       'format hex output with configurable grouping, and validate hex strings.'
  spec.homepage      = 'https://github.com/philiprehberger/rb-hex'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri']    = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri']   = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['bug_tracker_uri']       = "#{spec.homepage}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
