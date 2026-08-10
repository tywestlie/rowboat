class Dataset < ApplicationRecord
  has_many :dataset_columns, dependent: :destroy
  has_many :dataset_rows, dependent: :destroy
  has_many :queries, dependent: :destroy

  validates :name, presence: true

  def safe_source_url
    return nil unless source_url.present?

    URI.parse(source_url).scheme.in?(%w[http https]) ? source_url : nil
  rescue URI::InvalidURIError
    nil
  end
end
