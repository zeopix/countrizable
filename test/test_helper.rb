require 'rubygems'
require 'globalize'
require 'byebug'
require 'bundler/setup'

Bundler.require(:default, :test)

Dir[File.expand_path('../support/**/*.rb', __FILE__)].each { |f| require f }

Countrizable::Test::Database.connect

require File.expand_path('../data/models', __FILE__)
require 'minitest/autorun'
require 'minitest/reporters'
Minitest::Reporters.use!

require 'minitest/spec'

I18n.enforce_available_locales = true
I18n.available_locales = [ :en, :es ]

require 'database_cleaner'
DatabaseCleaner.strategy = :transaction

class MiniTest::Spec

  before :each do
    DatabaseCleaner.start
    I18n.locale = I18n.default_locale = :en
    Countrizable.country_code = :es
  end

  def assert_translated(record, locale, attributes, translations)
    assert_equal Array.wrap(translations), Array.wrap(attributes).map { |name| record.send(name, locale) }
  end

  def assert_country_valued(record, country_code, attributes, country_values)
    assert_equal Array.wrap(country_values), Array.wrap(attributes).map { |name| record.send(name, country_code) }
  end

end