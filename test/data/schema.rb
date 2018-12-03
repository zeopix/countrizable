ActiveRecord::Schema.define do

  create_table :products, :force => true do |t|
    t.string  :sku
    t.timestamps :null => false
  end

  create_table :product_translations, :force => true do |t|
    t.string     :locale
    t.references :product
    t.string     :title
    t.timestamps :null => false
  end

  create_table :shippings, :force => true do |t|
    t.references :product
    t.string     :sku
    t.timestamps :null => false
  end

  create_table :shipping_country_values do |t|
    t.references :shipping, index: true
    t.string :country_code, null: false, index: true
    t.decimal :price, default: 0, :precision => 8, :scale => 2
    t.timestamps
  end

  create_table :variants, :force => true do |t|
    t.references :product
    t.string  :sku
    t.timestamps :null => false
  end

  create_table :variant_translations, :force => true do |t|
    t.string     :locale
    t.references :variant
    t.string     :title
    t.timestamps :null => false
  end

  create_table :variant_country_values do |t|
    t.references :variant, index: true
    t.string :country_code, null: false, index: true
    t.decimal :price, default: 0, :precision => 8, :scale => 2
    t.timestamps
  end

end
