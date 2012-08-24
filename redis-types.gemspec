Gem::Specification.new do |s|
  s.name      = "redis-types"
  s.version   = "0.1.0"
  s.date      = Time.now.strftime('%Y-%m-%d')
  s.summary   = "Redis types as Ruby types"
  s.homepage  = "http://github.com/carlzulauf/redis-types"
  s.email     = "carl@linkleaf.com"
  s.authors   = [ "Carl Zulauf" ]
  s.has_rdoc  = false

  s.files     = %w( README.md Rakefile LICENSE )
  s.files    += Dir.glob("lib/**/*")
  s.files    += Dir.glob("spec/**/*")

  s.add_dependency "redis", ">= 2.2"
  s.add_dependency "redis-namespace-with-multi"
  s.add_dependency "activesupport"

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"

  s.description = "Expose Redis data types as close to native Ruby types as possible."
end
