class Product < ActiveRecord::Base
  attribute :sku
  translates :title
  country_attribute :price
end
