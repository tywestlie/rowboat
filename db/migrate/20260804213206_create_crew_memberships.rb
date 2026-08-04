class CreateCrewMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :crew_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :boat, null: false, foreign_key: true
      t.integer :role, null: false, default: 0
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :crew_memberships, [:user_id, :boat_id], unique: true
  end
end
