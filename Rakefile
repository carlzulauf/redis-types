require 'bundler'
Bundler.setup
require 'rake'
require 'bundler/gem_tasks'

task :default => :spec
task :test    => :spec

desc "Run specs"
task :spec do
  exec "rspec spec"
end
