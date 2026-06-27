class AddPricePeriodToStays < ActiveRecord::Migration[8.1]
  def change
    add_reference :stays, :price_period, null: false, foreign_key: true
  end
end
