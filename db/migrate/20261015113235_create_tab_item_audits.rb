class CreateTabItemAudits < ActiveRecord::Migration[8.1]
  def change
    create_table :tab_item_audits do |t|
      t.references :tab_item, null: false, foreign_key: true, index: true
      t.integer :action, null: false
      t.references :user, null: false, foreign_key: true
      t.text :reason
      t.jsonb :previous_state, null: false
      t.integer :tab_status_at_time, null: false

      t.timestamps
    end
  end
end
