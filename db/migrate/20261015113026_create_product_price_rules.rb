class CreateProductPriceRules < ActiveRecord::Migration[8.1]
  def change
    create_table :product_price_rules do |t|
      t.references :product, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.integer :priority, null: false, default: 0
      t.integer :days_of_week, array: true, default: []
      t.time :starts_at
      t.time :ends_at
      t.date :valid_from
      t.date :valid_until
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :product_price_rules, [ :product_id, :active, :priority ]
  end
end
