# frozen_string_literal: true

require_relative 'lib/awry/version'

Gem::Specification.new do |spec|
  spec.name          = 'awry'
  spec.version       = Awry::VERSION
  spec.authors       = ['Richard Lister']
  spec.email         = ['rlister+gh@gmail.com']

  spec.summary       = 'gem'
  spec.homepage      = 'https://github.com/rlister/awry'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.4.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'

  spec.add_dependency 'aws-sdk-cloudformation'
  spec.add_dependency 'aws-sdk-ec2'
  spec.add_dependency 'aws-sdk-rds'
  spec.add_dependency 'aws-sdk-s3'
  spec.add_dependency 'aws-sdk-secretsmanager'
  spec.add_dependency 'aws-sdk-ssm'
end
