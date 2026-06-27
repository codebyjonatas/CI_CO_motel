class CreatePricePeriods < ActiveRecord::Migration[8.1]
  def change
    create_table :price_periods do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.integer :duration_minutes, null: false
      t.boolean :overnight, null: false

      t.timestamps
    end
    add_index :price_periods, :code, unique: true
  end
end
