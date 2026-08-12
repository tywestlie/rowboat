class DatasetsController < ApplicationController
  def index
    @datasets = Dataset.order(:name).includes(:dataset_columns)
  end

  STARFIELD_FIELDS = %w[pl_rade sy_dist pl_eqt].freeze
  ORBITAL_PERIOD_FIELD = "pl_orbper"
  MIN_MULTI_PLANET_COUNT = 2
  SPECTRAL_CLASSES = %w[O B A F G K M].freeze

  def show
    @dataset = Dataset.find(params[:id])
    @columns = @dataset.dataset_columns.order(:position)
    @host = params[:hostname].presence
    @rows = filtered_rows.order(:id).page(params[:page]).per(50)
    @starfield_points = starfield_points if starfield_eligible?
    @starfield_mode = system_mode? ? "system" : "sky"
    @stellar_host = stellar_host_row if @host
  end

  def systems
    @dataset = Dataset.find(params[:id])
    @columns = @dataset.dataset_columns.order(:position)
    @include_single_planet = params[:all] == "1"
    @systems = system_counts
    @systems_chart_points = systems_chart_points
  end

  def random
    @dataset = Dataset.find(params[:id])
    @columns = @dataset.dataset_columns.order(:position)
    @row = @dataset.dataset_rows.order(Arel.sql("RANDOM()")).first
  end

  def extremes
    @dataset = Dataset.find(params[:id])
    @columns = @dataset.dataset_columns.order(:position)

    @leaderboards = {
      "Hottest" => numeric_top(:pl_eqt, :desc),
      "Coldest" => numeric_top(:pl_eqt, :asc),
      "Closest to Earth-size" => numeric_top(:pl_rade, :asc, distance_from: 1.0),
      "Most recently discovered" => numeric_top(:disc_year, :desc),
      "Closest to Earth" => numeric_top(:sy_dist, :asc)
    }
  end

  private

  def filtered_rows
    return @dataset.dataset_rows unless @host

    @dataset.dataset_rows.where("data->>'hostname' = ?", @host)
  end

  def has_hostname_column?
    @columns.map(&:name).include?("hostname")
  end

  def has_orbital_period_column?
    @columns.map(&:name).include?(ORBITAL_PERIOD_FIELD)
  end

  # Within a single system, sy_dist (distance from Earth) is the same for every
  # planet, so it collapses to a single x position when filtered to one host.
  # Orbital period varies planet-to-planet and is more informative here instead.
  def system_mode?
    @host.present? && has_orbital_period_column? &&
      @starfield_points.present? && @starfield_points.all? { |p| p[:pl_orbper].present? }
  end

  def starfield_eligible?
    (STARFIELD_FIELDS - @columns.map(&:name)).empty?
  end

  def starfield_points
    orbital_required = @host.present? && has_orbital_period_column?

    filtered_rows.pluck(:id, :data).filter_map do |id, data|
      next if STARFIELD_FIELDS.any? { |field| data[field].blank? }
      next if orbital_required && data[ORBITAL_PERIOD_FIELD].blank?

      point = {
        id: id,
        pl_name: data["pl_name"],
        pl_rade: data["pl_rade"].to_f,
        sy_dist: data["sy_dist"].to_f,
        pl_eqt: data["pl_eqt"].to_f
      }
      point[:pl_orbper] = data[ORBITAL_PERIOD_FIELD].to_f if data[ORBITAL_PERIOD_FIELD].present?
      point
    end
  end

  def system_counts
    return [] unless has_hostname_column?

    counts = @dataset.dataset_rows.group(Arel.sql("data->>'hostname'")).count
    counts = counts.reject { |name, _| name.blank? }
    counts = counts.select { |_, count| count >= MIN_MULTI_PLANET_COUNT } unless @include_single_planet

    counts.sort_by { |name, count| [ -count, name ] }
          .map { |name, count| { hostname: name, planet_count: count } }
  end

  def has_distance_and_temp_columns?
    names = @columns.map(&:name)
    names.include?("sy_dist") && names.include?("pl_eqt")
  end

  # Distance is the same for every planet in a system, so any row's value
  # would do, but temperature varies planet-to-planet, so both are averaged
  # per system. Systems where no row has a usable value for either field are
  # dropped rather than plotted with a fabricated average.
  def systems_chart_points
    return [] if @systems.empty? || !has_distance_and_temp_columns?

    hostnames = @systems.map { |system| system[:hostname] }
    values_by_host = @dataset.dataset_rows
      .where("data->>'hostname' IN (?)", hostnames)
      .pluck(
        Arel.sql("data->>'hostname'"),
        Arel.sql("NULLIF(data->>'sy_dist', '')::float"),
        Arel.sql("NULLIF(data->>'pl_eqt', '')::float")
      )
      .group_by { |hostname, _, _| hostname }

    spectral_classes = spectral_classes_by_hostname(hostnames)

    @systems.filter_map do |system|
      rows = values_by_host[system[:hostname]] || []
      distances = rows.filter_map { |_, distance, _| distance }
      temps = rows.filter_map { |_, _, temp| temp }
      next if distances.empty? || temps.empty?

      {
        hostname: system[:hostname],
        planet_count: system[:planet_count],
        avg_distance: (distances.sum / distances.size).round(2),
        avg_temp: (temps.sum / temps.size).round(1),
        spectral_class: spectral_classes[system[:hostname]]
      }
    end
  end

  # Spectral type strings look like "M8V" or "G2V"; the leading letter is the
  # spectral class used for coloring. Hosts with no Stellar Hosts row, a blank
  # st_spectype, or an unrecognized leading letter get nil (falls back to amber).
  def spectral_classes_by_hostname(hostnames)
    stellar_hosts = Dataset.find_by(name: "Stellar Hosts")
    return {} unless stellar_hosts

    stellar_hosts.dataset_rows
      .where("data->>'hostname' IN (?)", hostnames)
      .pluck(Arel.sql("data->>'hostname'"), Arel.sql("data->>'st_spectype'"))
      .each_with_object({}) do |(hostname, spectype), map|
        letter = spectype.to_s.strip[0]&.upcase
        map[hostname] = letter if SPECTRAL_CLASSES.include?(letter)
      end
  end

  def stellar_host_row
    stellar_hosts = Dataset.find_by(name: "Stellar Hosts")
    return nil unless stellar_hosts

    stellar_hosts.dataset_rows.find_by("data->>'hostname' = ?", @host)&.data
  end

  def numeric_top(field, direction, distance_from: nil)
    field_expr = ActiveRecord::Base.sanitize_sql_array([ "data->>?", field.to_s ])
    cast = "(#{field_expr})::float"
    scope = @dataset.dataset_rows.where(Arel.sql("#{field_expr} IS NOT NULL"))

    order_expr = distance_from ? "ABS(#{cast} - #{distance_from})" : cast
    order_direction = distance_from ? :asc : direction

    scope.order(Arel.sql("#{order_expr} #{order_direction.to_s.upcase}")).limit(5)
  end
end
