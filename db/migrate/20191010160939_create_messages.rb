class CreateMessages < ActiveRecord::Migration[5.1]
  def change
    create_table :messages do |t|
      t.bigint :cwmp_id
      t.datetime :timestamp
      t.string :ip
      t.string :method
      t.string :events
      t.string :oui
      t.string :product_class
      t.string :serial
      t.string :direction
      t.text :xml
      t.timestamps
    end
  end
end
