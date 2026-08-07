require "net/http"
require "csv"

class ImportExoplanetsJob < ApplicationJob
  queue_as :default

  EXOPLANET_URL = "https://exoplanetarchive.ipac.caltech.edu/TAP/sync?" \
    "query=select+pl_name,hostname,discoverymethod,disc_year,pl_orbper,pl_rade,pl_bmasse,pl_eqt,st_teff,sy_dist+from+pscomppars" \
    "&format=csv"

  COLUMN_DEFS = {
    "pl_name"         => { display: "Planet Name",           type: "string" },
    "hostname"        => { display: "Host Star",             type: "string" },
    "discoverymethod" => { display: "Discovery Method",      type: "string" },
    "disc_year"       => { display: "Discovery Year",        type: "integer" },
    "pl_orbper"       => { display: "Orbital Period (days)", type: "float" },
    "pl_rade"         => { display: "Radius (Earth radii)",  type: "float" },
    "pl_bmasse"       => { display: "Mass (Earth masses)",   type: "float" },
    "pl_eqt"          => { display: "Equilibrium Temp (K)",  type: "float" },
    "st_teff"         => { display: "Host Star Temp (K)",    type: "float" },
    "sy_dist"         => { display: "Distance (parsecs)",    type: "float" }
  }.freeze

  def perform
    response = Net::HTTP.get_response(URI(EXOPLANET_URL))
    raise "Fetch failed: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    csv_data = CSV.parse(response.body, headers: true)

    ActiveRecord::Base.transaction do
      dataset = Dataset.find_or_create_by!(name: "Confirmed Exoplanets") do |d|
        d.source_url = EXOPLANET_URL
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
