class MakeStayIdNullableInCleaningLogs < ActiveRecord::Migration[8.1]
  def change
    change_column_null :cleaning_logs, :stay_id, true
  end
end
