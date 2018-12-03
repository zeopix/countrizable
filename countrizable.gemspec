require File.expand_path('../lib/countrizable/version', __FILE__)

Gem::Specification.new do |s|
  s.name         = 'countrizable'
  s.version      = Countrizable::VERSION
  s.authors      = ['Iván Guillén']
  s.email        = 'zeopix@gmail.com'
  s.homepage     = 'http://github.com/zeopix/countrizable'
  s.summary      = 'Multicountry gem for rails and AR'
  s.description  = "Gem for implementing multi country sites, enables countrizable extension for ActiveRecord model/data."
  s.license      = "MIT"

  s.files        = Dir['{lib/**/*,[A-Z]*}']
  s.platform     = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.rubyforge_project = '[none]'
  s.required_ruby_version = '>= 2.0.0'

  s.add_dependency 'activerecord', '>= 4.2', '< 5.3'
  s.add_dependency 'activemodel', '>= 4.2', '< 5.3'
  s.add_dependency 'request_store', '~> 1.0'

  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'm'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'minitest-reporters'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'globalize'
end