class CreateRooms < ActiveRecord::Migration[8.1]
  def change
    create_table :rooms do |t|
      t.string :number, null: false
      t.integer :floor, default: 1
      t.decimal :daily_rate, precision: 10, scale: 2, default: 0.0, null: false
      t.integer :status, default: 0

      t.timestamps
    end
    add_index :rooms, :number, unique: true
  end
end
