class DropDatasetColumnsAndDatasetRows < ActiveRecord::Migration[8.1]
  def up
    drop_table :dataset_rows
    drop_table :dataset_columns
  end

  def down
    create_table :dataset_columns do |t|
      t.references :dataset, null: false, foreign_key: true
      t.string :name
      t.string :display_name
      t.string :data_type
      t.integer :position

      t.timestamps
    end

    create_table :dataset_rows do |t|
      t.references :dataset, null: false, foreign_key: true
      t.jsonb :data

      t.timestamps
    end
  end
end
