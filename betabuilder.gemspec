# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name              = "betabuilder"
  s.version           = "0.7.5"
  s.summary           = "A set of Rake tasks and utilities for managing iOS ad-hoc builds"
  s.authors           = ["Luke Redpath", "Nick Peelman"]
  s.email             = ["luke@lukeredpath.co.uk", "nick@peelman.us"]
  s.homepage          = "http://github.com/peelman/betabuilder"
  
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.date = "2012-04-25"
  s.extra_rdoc_files = ["README.md", "LICENSE", "CHANGES.md"]
  s.files = ["CHANGES.md", "LICENSE", "README.md", "lib/beta_builder/archived_build.rb", "lib/beta_builder/build_output_parser.rb", "lib/beta_builder/deployment_strategies/testflight.rb", "lib/beta_builder/deployment_strategies/web.rb", "lib/beta_builder/deployment_strategies.rb", "lib/beta_builder.rb", "lib/betabuilder.rb"]
  s.rdoc_options = ["--main", "README.md"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.11"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<CFPropertyList>, ["~> 2.0.0"])
      s.add_runtime_dependency(%q<uuid>, ["~> 2.3.1"])
      s.add_runtime_dependency(%q<rest-client>, ["~> 1.6.1"])
      s.add_runtime_dependency(%q<json>, ["~> 1.4.6"])
    else
      s.add_dependency(%q<CFPropertyList>, ["~> 2.0.0"])
      s.add_dependency(%q<uuid>, ["~> 2.3.1"])
      s.add_dependency(%q<rest-client>, ["~> 1.6.1"])
      s.add_dependency(%q<json>, ["~> 1.4.6"])
    end
  else
    s.add_dependency(%q<CFPropertyList>, ["~> 2.0.0"])
    s.add_dependency(%q<uuid>, ["~> 2.3.1"])
    s.add_dependency(%q<rest-client>, ["~> 1.6.1"])
    s.add_dependency(%q<json>, ["~> 1.4.6"])
  end
end
