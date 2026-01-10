class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.string :external_id
      t.string :provider_transaction_id
      t.integer :amount
      t.string :currency
      t.string :status

      t.timestamps
    end
  end
end
