# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "super_sti/version"

Gem::Specification.new do |s|
  s.name        = "super_sti"
  s.version     = SuperSTI::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jeremy Walker", "Alexander Kostrov"]
  s.email       = ["jez.walker@gmail.com", "bombazook@gmail.com"]
  s.homepage    = "https://github.com/iHiD/super_sti"
  s.summary     = %q{Ruby Rails - Add has_subject, belongs_to_subject to SDI models with clean database tables.}
  s.description = %q{Adds an has_subject and belongs_to_subject methods to ActiveRecord that find or create an extra data table. 
                    Means you can use STI but keep your database clean.}

  if RUBY_VERSION < "1.9.3"
    s.add_dependency "activerecord", "~> 3.2.0"
    s.add_dependency "activesupport", " ~> 3.2.0"
  else
    s.add_dependency "activerecord", ">= 3.2.0"
    s.add_dependency "activesupport", ">= 3.2.0"
  end
  s.add_development_dependency "rspec-rails"
  
  s.rubyforge_project = "has_extra_data"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
