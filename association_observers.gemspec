# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'association_observers/version'

Gem::Specification.new do |gem|
  gem.name          = "association_observers"
  gem.version       = AssociationObservers::VERSION
  gem.authors       = ["Tiago Cardoso"]
  gem.email         = ["tiago@restorm.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency("rake",["~> 0.9.2.2"])
  gem.add_development_dependency("rack-test",["=0.6.2"])
  gem.add_development_dependency("rspec",["~> 2.11.0"])
  gem.add_development_dependency("database_cleaner",["=0.8.0"])
  gem.add_development_dependency("colorize",["=0.5.8"])
  gem.add_development_dependency("pry")
  gem.add_development_dependency("pry-doc")
  gem.add_development_dependency("awesome_print")
end
