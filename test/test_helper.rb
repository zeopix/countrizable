require 'rubygems'
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
    Countrizable.country_code = nil
  end

  def with_fallbacks
    previous = I18n.backend
    I18n.backend = BackendWithFallbacks.new
    I18n.pretend_fallbacks
    return yield
  ensure
    I18n.hide_fallbacks
    I18n.backend = previous
  end

  def assert_belongs_to(model, other)
    assert_association(model, :belongs_to, other)
  end

  def assert_has_many(model, other)
    assert_association(model, :has_many, other)
  end

  def assert_association(model, type, other)
    assert model.reflect_on_all_associations(type).any? { |a| a.name == other }
  end

  def assert_translated(record, locale, attributes, translations)
    assert_equal Array.wrap(translations), Array.wrap(attributes).map { |name| record.send(name, locale) }
  end

end