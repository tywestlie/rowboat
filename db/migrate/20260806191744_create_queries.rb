class CreateQueries < ActiveRecord::Migration[8.1]
  def change
    create_table :queries do |t|
      t.references :dataset, null: false, foreign_key: true
      t.text :question
      t.jsonb :generated_query
      t.text :result_summary

      t.timestamps
    end
  end
end
