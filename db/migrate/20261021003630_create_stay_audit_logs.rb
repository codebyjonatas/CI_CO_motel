class CreateStayAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :stay_audit_logs do |t|
      t.references :stay, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :field_name, null: false
      t.integer :audit_action, null: false, default: 0
      t.text :previous_value
      t.text :new_value
      t.text :notes
      t.timestamps
    end

    add_index :stay_audit_logs, :created_at
  end
end
