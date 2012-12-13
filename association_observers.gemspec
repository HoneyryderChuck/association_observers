# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'association_observers/version'

Gem::Specification.new do |gem|
  gem.name          = "association_observers"
  gem.version       = AssociationObservers::VERSION
  gem.authors       = ["Tiago Cardoso"]
  gem.email         = ["cardoso_tiago@hotmail.com"]
  gem.description   = %q{This is an alternative implementation of the observer pattern. As you may know, Ruby (and Rails/ActiveRecord) already have an
  implementation of it. This implementation is a variation of the pattern, so it is not supposed to supersede the existing
  implementations, but "complete" them for the specific use-cases addressed.}
  gem.summary       = %q{The Observer Pattern clearly defines two roles: the observer and the observed. The observer registers itself by the
  observed. The observed decides when (for which "actions") to notify the observer. The observer knows what to do when notified.

  What's the limitation? The observed has to know when and whom to notify. The observer has to know what to do. For this
  logic to be implemented for two other separate entities, behaviour has to be copied from one place to the other. So, why
  not delegate this information (to whom, when, behaviour) to a third role, the notifier?}
  gem.homepage      = "https://github.com/TiagoCardoso1983/association_observers"

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

  gem.add_dependency("activesupport")
end
