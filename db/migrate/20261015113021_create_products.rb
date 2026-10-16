class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :code, limit: 20, null: false
      t.string :name, null: false
      t.integer :category, null: false, default: 99
      t.boolean :active, null: false, default: true
      t.decimal :price, precision: 10, scale: 2, null: false
      t.integer :tax_rate, null: false, default: 0
      t.text :description

      t.timestamps
    end
    add_index :products, :code, unique: true
    add_index :products, :category
    add_index :products, :active
  end
end
