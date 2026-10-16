class CreateTabs < ActiveRecord::Migration[8.1]
  def change
    create_table :tabs do |t|
      t.references :stay, null: true, foreign_key: true, index: true
      t.references :room, null: false, foreign_key: true, index: true
      t.references :opened_by, null: false, foreign_key: { to_table: :users }
      t.references :closed_by, null: true, foreign_key: { to_table: :users }
      t.string :guest_identifier
      t.integer :status, null: false, default: 0
      t.decimal :subtotal, precision: 10, scale: 2, null: false, default: 0
      t.decimal :discount, precision: 10, scale: 2, null: false, default: 0
      t.decimal :total, precision: 10, scale: 2, null: false, default: 0
      t.text :notes
      t.datetime :closed_at
      t.datetime :paid_at

      t.timestamps
    end

    add_index :tabs, [ :room_id, :status ], where: "status IN (0,1)"
    add_index :tabs, [ :stay_id, :status ]
  end
end
