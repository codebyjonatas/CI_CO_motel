class AddCleaningWorkflowToRooms < ActiveRecord::Migration[8.1]
  def change
    # status column already exists from original schema
    add_column :rooms, :cleaning_started_at, :datetime
    add_column :rooms, :cleaning_finished_at, :datetime
    add_column :rooms, :quarantine_until, :datetime
    add_reference :rooms, :cleaned_by, null: true, foreign_key: { to_table: :users }

    # Índices para queries de disponibilidade
    add_index :rooms, :status
    add_index :rooms, :quarantine_until
    add_index :rooms, [ :status, :quarantine_until ], where: "status IN (3,4)" # cleaning, quarantine
  end
end
