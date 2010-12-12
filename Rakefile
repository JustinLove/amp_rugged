require 'rubygems'
require 'rake'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new do |t|
  #spec.libs << 'lib' << 'spec'
  t.pattern = 'spec/**/*_spec.rb'
end

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/test*.rb']
  t.verbose = true
end

begin
  require 'cucumber/rake/task'
  Cucumber::Rake::Task.new(:features)
rescue LoadError
  task :features do
    abort 'Cucumber is not available. In order to run features, you must: sudo gem install cucumber'
  end
end

task :default => [:spec, :test]

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yardoc do
    abort 'YARD is not available. In order to run yardoc, you must: sudo gem install yard'
  end
end
