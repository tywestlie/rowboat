class CreateDatasetRows < ActiveRecord::Migration[8.1]
  def change
    create_table :dataset_rows do |t|
      t.references :dataset, null: false, foreign_key: true
      t.jsonb :data

      t.timestamps
    end
  end
end
