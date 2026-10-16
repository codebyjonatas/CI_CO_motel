class CreateCleaningLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :cleaning_logs do |t|
      t.references :room, null: false, foreign_key: true, index: true
      t.references :stay, null: true, foreign_key: true, index: true
      t.references :cleaned_by, null: false, foreign_key: { to_table: :users }
      t.references :inspected_by, null: true, foreign_key: { to_table: :users }
      t.integer :status, null: false, default: 0
      t.datetime :started_at
      t.datetime :finished_at
      t.datetime :inspected_at
      t.text :notes
      t.text :rejection_reason

      t.timestamps
    end

    add_index :cleaning_logs, [ :room_id, :created_at ]
    add_index :cleaning_logs, :status
  end
end
