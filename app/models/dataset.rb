class Dataset < ApplicationRecord
  has_many :dataset_columns, dependent: :destroy
  has_many :dataset_rows, dependent: :destroy
  has_many :queries, dependent: :destroy

  validates :name, presence: true

  def has_column?(name)
    column_names.include?(name.to_s)
  end

  def safe_source_url
    return nil unless source_url.present?

    URI.parse(source_url).scheme.in?(%w[http https]) ? source_url : nil
  rescue URI::InvalidURIError
    nil
  end

  private

  def column_names
    @column_names ||= dataset_columns.pluck(:name).to_set
  end
end
