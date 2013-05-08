# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redmine_acts_as_taggable_on/version'

Gem::Specification.new do |spec|
  spec.name          = "redmine_acts_as_taggable_on"
  spec.version       = RedmineActsAsTaggableOn::VERSION
  spec.authors       = ["Harry Garrood"]
  spec.email         = ["hdgarrood@gmail.com"]
  spec.description   = %q{Allows multiple Redmine plugins to use tags safely}
  spec.summary       = %q{Allows multiple Redmine plugins to use the acts_as_taggable_on gem without stepping on each others' toes.}
  spec.homepage      = "https://github.com/hdgarrood/redmine_acts_as_taggable_on"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
