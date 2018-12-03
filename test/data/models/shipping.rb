class Shipping < ActiveRecord::Base
  country_attribute :price
  belongs_to :product
end
