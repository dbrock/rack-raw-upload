Gem::Specification.new do |gem|
  gem.name = 'rack-raw-upload'
  gem.version = '0.1.0'
  gem.authors = ['Daniel Brockman']
  gem.email = ['daniel@brockman.se']
  gem.homepage = 'http://github.com/dbrock/rack-raw-upload'
  gem.summary = 'Rack middleware to handle raw file uploads.'
  gem.files = ['lib/rack-raw-upload.rb']
  gem.add_dependency 'rack'
  gem.add_dependency 'json'
  gem.add_development_dependency 'rack-test'
  gem.add_development_dependency 'shoulda'
end
