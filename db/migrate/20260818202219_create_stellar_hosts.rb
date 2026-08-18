class CreateStellarHosts < ActiveRecord::Migration[8.1]
  def change
    create_table :stellar_hosts do |t|
      t.string :hostname
      t.string :st_spectype
      t.float :st_teff
      t.float :st_rad
      t.float :st_mass
      t.float :st_met
      t.float :st_lum
      t.float :sy_dist
      t.float :ra
      t.float :dec

      t.timestamps
    end
    add_index :stellar_hosts, :hostname, unique: true
  end
end
