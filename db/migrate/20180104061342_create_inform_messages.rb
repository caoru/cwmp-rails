class CreateInformMessages < ActiveRecord::Migration[5.1]
  def change
    create_table :inform_messages do |t|
      t.integer :rid
      t.string :received
      t.string :ip
      t.string :oui
      t.string :class
      t.string :serial
      t.string :event
      t.string :xml

      t.timestamps
    end
  end
end
