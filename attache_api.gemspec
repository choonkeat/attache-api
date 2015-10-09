$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem"s version:
require "attache/api/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "attache_api"
  s.version     = Attache::API::VERSION
  s.authors     = ["choonkeat"]
  s.email       = ["choonkeat@gmail.com"]
  s.homepage    = "https://github.com/choonkeat/attache_api"
  s.summary     = "API for client lib to integrate with attache server"
  s.license     = "MIT"

  s.files       = Dir["{app,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_runtime_dependency "httpclient"

  s.add_development_dependency "rake"
  s.add_development_dependency "fastimage"
  s.add_development_dependency "minitest"
  s.add_development_dependency "guard"
  s.add_development_dependency "guard-minitest"
end
