require File.expand_path('../test_helper', __FILE__)

class CountrizableTest < MiniTest::Spec

  before :each do
    Product.create(
      :title => 'titulo',
      :price => '10'
    )
  end

  describe 'translated and country valued record' do
    it "saves and restores for given country code and locale" do

      Countrizable.country_code = :es
      I18n.locale = :es
      p = Product.create(
        :title => 'titulo',
        :price => '10'
      )

      Countrizable.country_code = :de
      I18n.locale = :en
      p.title = 'title'
      p.price = '20'
      p.save!

      Countrizable.country_code = :es
      I18n.locale = :es
      rest_p = Product.find(p.id)
      assert_translated rest_p, :es, :title, 'titulo'
      assert_country_valued rest_p, :es, :price, '10'

      Countrizable.country_code = :de
      I18n.locale = :en

      assert_translated rest_p, :en, :title, 'title'
      assert_country_valued rest_p, :de, :price, '20'
    end
  end
end  
