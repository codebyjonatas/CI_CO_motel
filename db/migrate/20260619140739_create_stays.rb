class CreateStays < ActiveRecord::Migration[8.1]
  def change
    create_table :stays do |t|
      t.references :room, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :check_in, null: false
      t.datetime :check_out
      t.decimal :total_value, precision: 10, scale: 2
      t.text :observation
      t.date :date, null: false
      t.integer :week_number, null: false
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
