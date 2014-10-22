# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lzop/file/version'

Gem::Specification.new do |spec|
  spec.name          = "lzop-file"
  spec.version       = LZOP::File::VERSION
  spec.authors       = ["James Cuzella"]
  spec.email         = ["james.cuzella@lyraphase.com"]
  spec.summary       = %q{Gem for reading and writing LZO files (similar to lzop command)}
  spec.description   = File.join( File.dirname(__FILE__), 'README.md')
  spec.homepage      = "https://github.com/trinitronx/lzop-file"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "lzoruby", "~> 0.1.3"

  spec.add_development_dependency "rspec"
  spec.add_development_dependency "simplecov", "~> 0.9.0"
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
