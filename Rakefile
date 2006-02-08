require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rubygems'

GEOCODER_VERSION = "0.1.0"

PKG_FILES = FileList["lib/**/*", "bin/**/*", "[A-Z]*",
  "test/**/*"].exclude(/\b\.svn\b/)

desc "Run all tests"
task :default => [ :test ]

desc "Run all tests"
task :test do
  ruby "test/ts_geocoder.rb"
end

desc "Generate documentation"
task :docs do
  sh "rdoc -S -N -o doc -t \"Geocoder Documentation\" README TODO lib"
end

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.summary = "Geocoding library and CLI."
  s.name = "geocoder"
  s.version = GEOCODER_VERSION
  s.requirements << "none"
  s.require_path = "lib"
  s.author = "Paul Smith"
  s.files = PKG_FILES
  s.email = "paul@cnt.org"
  s.rubyforge_project = "geocoder"
  s.homepage = "http://geocoder.rubyforge.org"
  s.bindir = "bin"
  s.executables = ["geocode"]
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end