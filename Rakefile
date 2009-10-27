require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/testtask'
require 'rake/rdoctask'

$:.unshift File.dirname(__FILE__) + '/lib'
require 'ape'

def spec
  spec ||= Gem::Specification.new do |s|
    s.platform = Gem::Platform::RUBY
    s.name = 'ape'
    s.version = Ape::VERSION::STRING
    s.authors = ['Tim Bray', 'David Calavera']
    s.email = ['tim.bray@sun.com', 'calavera@apache.org']
    s.homepage = 'http://ape.rubyforge.org'
    s.summary = 'The Atom Protocol Exerciser'

    s.files = FileList['lib/**/*', 'samples/*', 'test/**/*', 'web/*',
                                   'README', 'LICENSE', 'Rakefile'].to_ary
    s.bindir = 'bin'
    s.executable = 'ape_server'

    s.has_rdoc = true
    s.extra_rdoc_files = ['README', 'LICENSE']

    s.rubyforge_project = 'ape'

    s.add_dependency 'rake', '>= 0.8'
    s.add_dependency 'mongrel', '>= 1.1.3'
    s.add_dependency 'erubis', '>= 2.5.0'
    s.add_dependency 'rubyforge', '>= 0.4'
    s.add_dependency 'mocha', '>= 0.9.0'
  end
end

def install_gem(*args)
  cmd = []
  cmd << "#{'sudo ' unless Gem.win_platform?}gem install"
  sh cmd.push(*args.flatten).join(" ")
end

desc 'Install the necessary dependencies'
task :setup do
  installed = Gem::SourceIndex.from_installed_gems  
  dependencies = spec.dependencies
  dependencies.select { |dep|
    installed.find_name(dep.name, dep.version_requirements).empty? }.each do |dep|
      puts "Installing #{dep} ..."
      install_gem dep.name, "-v '#{dep.version_requirements.to_s}'"
    end
end

# The default task is run if rake is given no explicit arguments.
desc "Default Task"
task :default => :test

# Test Tasks ---------------------------------------------------------

desc "Run all tests"
task :test => [:test_units]

Rake::TestTask.new("test_units") do |t|
  t.test_files = FileList['test/unit/*test.rb']
  t.verbose = false  
end

# Rdoc ---------------------------------------------------------------

Rake::RDocTask.new do |t|
  t.main = 'README'
  t.rdoc_files.include('README', 'LICENSE', 'lib/**/*.rb')
end
