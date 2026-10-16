class CreateTabItems < ActiveRecord::Migration[8.1]
  def change
    create_table :tab_items do |t|
      t.references :tab, null: false, foreign_key: true, index: true
      t.references :product, null: false, foreign_key: true
      t.references :added_by, null: false, foreign_key: { to_table: :users }
      t.references :voided_by, null: true, foreign_key: { to_table: :users }
      t.integer :quantity, null: false, default: 1
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.decimal :total_price, precision: 10, scale: 2, null: false
      t.integer :status, null: false, default: 0
      t.text :notes
      t.datetime :voided_at

      t.timestamps
    end
  end
end
