class CreateDatasets < ActiveRecord::Migration[8.1]
  def change
    create_table :datasets do |t|
      t.string :name
      t.string :source_url
      t.datetime :imported_at
      t.integer :row_count

      t.timestamps
    end
  end
end
