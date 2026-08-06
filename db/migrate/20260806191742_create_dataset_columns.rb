class CreateDatasetColumns < ActiveRecord::Migration[8.1]
  def change
    create_table :dataset_columns do |t|
      t.references :dataset, null: false, foreign_key: true
      t.string :name
      t.string :display_name
      t.string :data_type
      t.integer :position

      t.timestamps
    end
  end
end
