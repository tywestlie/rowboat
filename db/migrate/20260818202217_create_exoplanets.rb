class CreateExoplanets < ActiveRecord::Migration[8.1]
  def change
    create_table :exoplanets do |t|
      t.string :pl_name
      t.string :hostname
      t.string :discoverymethod
      t.integer :disc_year
      t.float :pl_orbper
      t.float :pl_rade
      t.float :pl_bmasse
      t.float :pl_eqt
      t.float :st_teff
      t.float :sy_dist

      t.timestamps
    end
    add_index :exoplanets, :hostname
  end
end
