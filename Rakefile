require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/testtask'
require 'rake/rdoctask'

$:.unshift File.dirname(__FILE__) + '/lib'
require 'ape'

ape_dependencies = {
  :rake => '>= 0.8',
  :mongrel => '>= 1.1.3',
  :erubis => '>= 2.5.0',
  :mocha => '>= 0.9.0'
}

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
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

    ape_dependencies.each do |name, version|
      s.add_dependency name.to_s, version
    end
  end

  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

def install_gem(*args)
  cmd = []
  cmd << "#{'sudo ' unless Gem.win_platform?}gem install"
  sh cmd.push(*args.flatten).join(" ")
end

desc 'Install the necessary dependencies'
task :setup do
  installed = Gem::SourceIndex.from_installed_gems  
  ape_dependencies.select { |name, version|
    installed.find_name(name.to_s, version).empty? }.each do |dep|
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
