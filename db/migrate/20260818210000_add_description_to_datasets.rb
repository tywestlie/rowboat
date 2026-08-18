class AddDescriptionToDatasets < ActiveRecord::Migration[8.1]
  def change
    add_column :datasets, :description, :text
  end
end
