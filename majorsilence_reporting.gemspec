# frozen_string_literal: true

require_relative 'lib/majorsilence_reporting/version'

Gem::Specification.new do |spec|
  spec.name        = 'majorsilence_reporting'
  spec.version     = MajorsilenceReporting::VERSION
  spec.authors     = ['Peter Gill']
  spec.email       = ['peter@majorsilence.com']

  spec.summary     = 'Ruby bindings for Majorsilence Reporting'
  spec.description = 'Ruby wrappers for Majorsilence Reporting -- render RDL reports to PDF, ' \
                      'Excel, CSV, HTML and more via an in-process native library (Fiddle FFI) ' \
                      'or a subprocess-based .NET runner.'
  spec.homepage    = 'https://github.com/majorsilence/Reporting'
  spec.licenses    = ['MIT', 'Apache-2.0', 'BSD-2-Clause']

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = 'https://github.com/majorsilence/reporting-ruby'
  spec.metadata['changelog_uri']         = 'https://github.com/majorsilence/reporting-ruby/releases'
  spec.metadata['bug_tracker_uri']       = 'https://github.com/majorsilence/reporting-ruby/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.required_ruby_version = '>= 3.0'

  spec.files = Dir['lib/**/*.rb'] + Dir['LICENSE*'] + ['README.md']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 13.0'
end
