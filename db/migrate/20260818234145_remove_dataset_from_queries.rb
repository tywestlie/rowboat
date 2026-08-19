class RemoveDatasetFromQueries < ActiveRecord::Migration[8.1]
  def change
    remove_reference :queries, :dataset, null: false, foreign_key: true
  end
end
