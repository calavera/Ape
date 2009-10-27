Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
  pkg.need_zip = false
  pkg.gem_spec = spec
end

namespace :deploy do

desc 'Install the package as a gem'
task :install => [:clean, :package] do
  install_gem "pkg/#{spec.name}-#{spec.version}.gem"
end

desc 'Install the package as a gem, without generating documentation(ri/rdoc)'
task :install_no_doc => [:clean, :package] do
  install_gem "pkg/#{spec.name}-#{spec.version}.gem --no-rdoc --no-ri"
end

begin
  require 'rubyforge'  
rescue LoadError
  puts 'Please run rake setup to install the RubyForge gem'
  task :setup do
    gem_install 'rubyforge'
  end  
end

desc 'Upload the released package to rubyforge'
task :release => :package do
  puts "Uploading the ape #{spec.version} to RubyForge ... "
  files = Dir.glob('pkg/*.{gem,tgz}')
  rubyforge = RubyForge.new
  rubyforge.configure
  rubyforge.login
  rubyforge.add_release spec.rubyforge_project.downcase, spec.name.downcase, spec.version, *files
  puts 'Done'
end

end