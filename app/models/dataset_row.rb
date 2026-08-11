class DatasetRow < ApplicationRecord
  belongs_to :dataset

  def method_missing(name, *args)
    return super unless args.empty?
    return super unless dataset.has_column?(name)

    data[name.to_s]
  end

  def respond_to_missing?(name, include_private = false)
    dataset.has_column?(name) || super
  end
end
