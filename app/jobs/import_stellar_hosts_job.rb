require "net/http"
require "csv"

class ImportStellarHostsJob < ApplicationJob
  queue_as :default

  STELLAR_HOSTS_URL = "https://exoplanetarchive.ipac.caltech.edu/TAP/sync?" \
    "query=select+hostname,st_spectype,st_teff,st_rad,st_mass,st_met,st_lum,sy_dist,ra,dec+from+stellarhosts" \
    "&format=csv"

  COLUMN_DEFS = {
    "hostname"    => { display: "Host Star",              type: "string" },
    "st_spectype" => { display: "Spectral Type",           type: "string" },
    "st_teff"     => { display: "Temperature (K)",         type: "float" },
    "st_rad"      => { display: "Radius (Solar radii)",    type: "float" },
    "st_mass"     => { display: "Mass (Solar masses)",     type: "float" },
    "st_met"      => { display: "Metallicity",             type: "float" },
    "st_lum"      => { display: "Luminosity (log Solar)",  type: "float" },
    "sy_dist"     => { display: "Distance (parsecs)",      type: "float" },
    "ra"          => { display: "Right Ascension",         type: "float" },
    "dec"         => { display: "Declination",             type: "float" }
  }.freeze

  def perform
    response = Net::HTTP.get_response(URI(STELLAR_HOSTS_URL))
    raise "Fetch failed: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    csv_data = CSV.parse(response.body, headers: true)

    ActiveRecord::Base.transaction do
      dataset = Dataset.find_or_create_by!(name: "Stellar Hosts") do |d|
        d.source_url = STELLAR_HOSTS_URL
      end

      dataset.dataset_rows.destroy_all
      dataset.dataset_columns.destroy_all

      COLUMN_DEFS.each_with_index do |(col_name, meta), index|
        dataset.dataset_columns.create!(
          name: col_name,
          display_name: meta[:display],
          data_type: meta[:type],
          position: index
        )
      end

      rows = csv_data.map do |row|
        {
          dataset_id: dataset.id,
          data: COLUMN_DEFS.keys.index_with { |col| row[col] },
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      DatasetRow.insert_all(rows) if rows.any?
      dataset.update!(imported_at: Time.current, row_count: rows.size)
    end
  end
end
