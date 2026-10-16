class CreateRoomStatusLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :room_status_logs do |t|
      t.references :room, null: false, foreign_key: true, index: true
      t.references :stay, null: true, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true
      t.integer :from_status, null: false
      t.integer :to_status, null: false
      t.integer :trigger, null: false
      t.text :notes

      t.timestamps
    end

    add_index :room_status_logs, [ :room_id, :created_at ]
  end
end
