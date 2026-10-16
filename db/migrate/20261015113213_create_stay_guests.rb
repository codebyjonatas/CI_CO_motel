class CreateStayGuests < ActiveRecord::Migration[8.1]
  def change
    create_table :stay_guests do |t|
      t.references :stay, null: false, foreign_key: true, index: true
      t.string :full_name, null: false
      t.string :document
      t.integer :document_type, null: false, default: 0
      t.date :birth_date
      t.string :phone
      t.string :email
      t.boolean :main_guest, null: false, default: false

      t.timestamps
    end

    add_index :stay_guests, [ :stay_id, :main_guest ], unique: true, where: "main_guest = true"
  end
end
