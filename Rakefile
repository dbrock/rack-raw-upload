require 'rake/testtask'
require 'jeweler'

task :default => :test

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end

Jeweler::Tasks.new do |gem|
  gem.name = "rack-raw-upload"
  gem.summary = "Rack middleware to handle raw file uploads."
  gem.homepage = "http://github.com/dbrock/rack-raw-upload"
  gem.files = FileList["lib/rack/raw-upload.rb"]
  gem.add_dependency('rack')
  gem.add_dependency('json')
  gem.add_development_dependency('rack-test')
  gem.add_development_dependency('shoulda')
end
