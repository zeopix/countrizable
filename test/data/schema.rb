ActiveRecord::Schema.define do

  create_table :products, :force => true do |t|
    t.string  :sku, unique:true
    t.timestamps :null => false
  end

  create_table :product_translations, :force => true do |t|
    t.string     :locale
    t.references :product
    t.string     :title
    t.timestamps :null => false
  end

  create_table :product_country_values, :force => true do |t|
    t.string     :country_code
    t.references :product
    t.string     :price
    t.timestamps :null => false
  end

end
