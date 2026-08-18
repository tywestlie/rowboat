require "net/http"
require "csv"

class ImportStellarHostsJob < ApplicationJob
  queue_as :default

  STELLAR_HOSTS_URL = "https://exoplanetarchive.ipac.caltech.edu/TAP/sync?" \
    "query=select+hostname,st_spectype,st_teff,st_rad,st_mass,st_met,st_lum,sy_dist,ra,dec+from+stellarhosts" \
    "&format=csv"

  STRING_COLUMNS = %w[hostname st_spectype].freeze
  FLOAT_COLUMNS = %w[st_teff st_rad st_mass st_met st_lum sy_dist ra dec].freeze
  ALL_COLUMNS = (STRING_COLUMNS + FLOAT_COLUMNS).freeze

  def perform
    response = Net::HTTP.get_response(URI(STELLAR_HOSTS_URL))
    raise "Fetch failed: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    csv_data = CSV.parse(response.body, headers: true)

    ActiveRecord::Base.transaction do
      StellarHost.delete_all

      rows = dedupe_by_hostname(csv_data).map { |row| row_attributes(row) }
      StellarHost.insert_all(rows) if rows.any?

      dataset = Dataset.find_or_create_by!(name: "Stellar Hosts") do |d|
        d.source_url = STELLAR_HOSTS_URL
      end
      dataset.update!(source_url: STELLAR_HOSTS_URL, imported_at: Time.current, row_count: rows.size)
    end
  end

  private

  # The archive's stellarhosts table has one row per publication that reported
  # stellar parameters for a host, not one row per star, so the same hostname
  # can appear many times with differing completeness. Keep the most complete
  # row (fewest blank fields) per hostname, breaking ties by CSV order.
  def dedupe_by_hostname(csv_data)
    csv_data
      .group_by { |row| row["hostname"] }
      .values
      .map { |rows| rows.min_by { |row| ALL_COLUMNS.count { |col| row[col].blank? } } }
  end

  def row_attributes(row)
    now = Time.current
    attrs = { created_at: now, updated_at: now }
    STRING_COLUMNS.each { |col| attrs[col.to_sym] = row[col] }
    FLOAT_COLUMNS.each { |col| attrs[col.to_sym] = row[col].presence&.to_f }
    attrs
  end
end
