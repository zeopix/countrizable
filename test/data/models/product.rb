class Product < ActiveRecord::Base
  attribute :sku
  country_attribute :price
  translates :title
end
