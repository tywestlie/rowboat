class CreateBoats < ActiveRecord::Migration[8.1]
  def change
    create_table :boats do |t|
      t.string :name
      t.string :boat_type
      t.decimal :length_feet
      t.string :home_port
      t.text :description
      t.references :owner, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
