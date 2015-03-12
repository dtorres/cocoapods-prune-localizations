# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-prune-localizations.rb'

Gem::Specification.new do |spec|
  spec.name          = "cocoapods-prune-localizations"
  spec.version       = CocoapodsPruneLocalizations::VERSION
  spec.authors       = ["Diego Torres"]
  spec.email         = ["contact@dtorres.me"]
  spec.description   = %q{Remove unused localizations from your app}
  spec.summary       = %q{Upon running pod install, this plugin will remove unused localizations by your project}
  spec.homepage      = "https://github.com/dtorres/cocoapods-prune-localizations"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
