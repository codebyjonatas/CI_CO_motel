class RemovePricePeriodFkFromStays < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :stays, :price_periods
    # Mantém a coluna price_period_id para histórico, mas sem FK
  end
end
