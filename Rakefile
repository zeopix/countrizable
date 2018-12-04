require 'rake'
require 'rake/testtask'
require 'rdoc/task'

begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

desc 'Generate documentation.'
RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Countrizable'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.md')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :load_path do
  %w(lib test).each do |path|
    $LOAD_PATH.unshift(File.expand_path("../#{path}", __FILE__))
  end
end

desc 'Default: run unit tests.'
task :default => :test

desc 'Run all tests.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

namespace :db do
  desc 'Create the database'
  task :create => :load_path do
    require 'support/database'

    Countrizable::Test::Database.create!
  end

  desc "Drop the database"
  task :drop => :load_path do
    require 'support/database'

    Countrizable::Test::Database.drop!
  end

  desc "Set up the database schema"
  task :migrate => :load_path do
    require 'support/database'

    Countrizable::Test::Database.migrate!
    # ActiveRecord::Schema.migrate :up
  end

  desc "Drop and recreate the database schema"
  task :reset => [:drop, :create]
end
