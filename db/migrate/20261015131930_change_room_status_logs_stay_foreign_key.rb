class ChangeRoomStatusLogsStayForeignKey < ActiveRecord::Migration[8.1]
  def change
    # Remove the existing foreign key constraint
    remove_foreign_key :room_status_logs, :stays, name: "fk_rails_17fffe0a11"

    # Add new foreign key with ON DELETE NULLIFY
    # This allows stays to be deleted while preserving audit logs with stay_id set to NULL
    add_foreign_key :room_status_logs, :stays, on_delete: :nullify
  end
end
