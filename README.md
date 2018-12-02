# Countrizable
Countrizable is a gem to use on top of ruby on rails to add model contents depending on country.
Inspired in [![Globalize]](https://github.com/globalize/globalize)

## Requirements

* ActiveRecord >= 4.2.0 (see below for installation with ActiveRecord 3.x)
* I18n

## Installation

To install the ActiveRecord 4.2.x compatible version of Globalize with its default setup, just use:

```ruby
gem install countrizable
```

When using bundler put this in your Gemfile:

```ruby
gem 'countrizable'
```

## Model country attributes

Model country attributes allow you to translate your models' depending on gem's selected country. E.g.

```ruby
class Product < ActiveRecord::Base
  country_attribure :price
  country_attribure :currency
end
```

Allows you to translate the attributes :price and :currency per country_code:

```ruby
Countrizable.country_code = :uk
product.price # =>  3.00
product.currency # => Pound

Countrizable.country_code = :de
product.price # =>  3.60
product.currency # => Euro
```

You can also set values with mass-assignment by specifying the country_code:

```ruby
product.attributes = { price: 4.5, country_code: :uk }
```

In order to make this work, you'll need to add the appropriate country attribute tables.
Countrizable comes with a handy helper method to help you do this.
It's called `create_country_value_table!`. Here's an example:

Note that your migrations can use `create_country_value_table!` and `drop_country_value_table!`
only inside the `up` and `down` instance methods, respectively. You cannot use `create_country_value_table!`
and `drop_country_value_table!` inside the `change` instance method.

### Creating country value tables

Also note that before you can create a country value table, you have to define the country attributes via `country_attribute` in your model as shown above.

```ruby
class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.timestamps
    end
    
    #creating country value tables
    reversible do |dir|
      dir.up do
        Product.create_country_value_table!({
          :price => :decimal, default: 0, :precision => 8, :scale => 2,
          :currency => :string
        })
      end

      dir.down do
        Product.drop_country_value_table!
      end
    end

    #compatible with globalize gem
    reversible do |dir|
      dir.up do
        Product.create_translation_table! :title => :string, :text => :text
      end

      dir.down do
        Product.drop_translation_table!
      end
    end
  end
end
```