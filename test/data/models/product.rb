class Product < ActiveRecord::Base
  translates :title
  accepts_nested_attributes_for :translations
  has_many :variants
  has_one :shipment
end
