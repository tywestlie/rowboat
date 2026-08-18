require "net/http"
require "csv"

class ImportExoplanetsJob < ApplicationJob
  queue_as :default

  EXOPLANET_URL = "https://exoplanetarchive.ipac.caltech.edu/TAP/sync?" \
    "query=select+pl_name,hostname,discoverymethod,disc_year,pl_orbper,pl_rade,pl_bmasse,pl_eqt,st_teff,sy_dist+from+pscomppars" \
    "&format=csv"

  STRING_COLUMNS = %w[pl_name hostname discoverymethod].freeze
  INTEGER_COLUMNS = %w[disc_year].freeze
  FLOAT_COLUMNS = %w[pl_orbper pl_rade pl_bmasse pl_eqt st_teff sy_dist].freeze

  def perform
    response = Net::HTTP.get_response(URI(EXOPLANET_URL))
    raise "Fetch failed: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    csv_data = CSV.parse(response.body, headers: true)

    ActiveRecord::Base.transaction do
      Exoplanet.delete_all

      rows = csv_data.map { |row| row_attributes(row) }
      Exoplanet.insert_all(rows) if rows.any?

      dataset = Dataset.find_or_create_by!(name: "Confirmed Exoplanets") do |d|
        d.source_url = EXOPLANET_URL
      end
      dataset.update!(source_url: EXOPLANET_URL, imported_at: Time.current, row_count: rows.size)
    end
  end

  private

  def row_attributes(row)
    now = Time.current
    attrs = { created_at: now, updated_at: now }
    STRING_COLUMNS.each { |col| attrs[col.to_sym] = row[col] }
    INTEGER_COLUMNS.each { |col| attrs[col.to_sym] = row[col].presence&.to_i }
    FLOAT_COLUMNS.each { |col| attrs[col.to_sym] = row[col].presence&.to_f }
    attrs
  end
end
