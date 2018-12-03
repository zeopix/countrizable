class Variant < ActiveRecord::Base
  translates :title
  country_attribute :price
  accepts_nested_attributes_for :translations
  belongs_to :product
end
