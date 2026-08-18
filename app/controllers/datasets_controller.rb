class DatasetsController < ApplicationController
  def index
    @datasets = Dataset.order(:name)
  end

  MIN_MULTI_PLANET_COUNT = 2
  SPECTRAL_CLASSES = %w[O B A F G K M].freeze

  def show
    @dataset = Dataset.find(params[:id])
    @host = params[:hostname].presence
    @exoplanets = filtered_exoplanets.order(:id).page(params[:page]).per(50)
    @starfield_points = starfield_points
    @starfield_mode = system_mode? ? "system" : "sky"
    @stellar_host = @host ? @exoplanets.first&.stellar_host : nil
  end

  def systems
    @dataset = Dataset.find(params[:id])
    @include_single_planet = params[:all] == "1"
    @systems = system_counts
    @systems_chart_points = systems_chart_points
  end

  def random
    @dataset = Dataset.find(params[:id])
    @exoplanet = Exoplanet.order(Arel.sql("RANDOM()")).first
  end

  def extremes
    @dataset = Dataset.find(params[:id])

    @leaderboards = {
      "Hottest" => Exoplanet.where.not(pl_eqt: nil).order(pl_eqt: :desc).limit(5),
      "Coldest" => Exoplanet.where.not(pl_eqt: nil).order(pl_eqt: :asc).limit(5),
      "Closest to Earth-size" => Exoplanet.where.not(pl_rade: nil).order(Arel.sql("ABS(pl_rade - 1.0) ASC")).limit(5),
      "Most recently discovered" => Exoplanet.where.not(disc_year: nil).order(disc_year: :desc).limit(5),
      "Closest to Earth" => Exoplanet.where.not(sy_dist: nil).order(sy_dist: :asc).limit(5)
    }
  end

  private

  def filtered_exoplanets
    return Exoplanet.all unless @host

    Exoplanet.where(hostname: @host)
  end

  # Within a single system, sy_dist (distance from Earth) is the same for every
  # planet, so it collapses to a single x position when filtered to one host.
  # Orbital period varies planet-to-planet and is more informative here instead.
  def system_mode?
    @host.present? && @starfield_points.present? && @starfield_points.all? { |p| p[:pl_orbper].present? }
  end

  def starfield_points
    orbital_required = @host.present?

    scope = filtered_exoplanets.where.not(pl_rade: nil).where.not(sy_dist: nil).where.not(pl_eqt: nil)
    scope = scope.where.not(pl_orbper: nil) if orbital_required

    scope.pluck(:id, :pl_name, :pl_rade, :sy_dist, :pl_eqt, :pl_orbper).map do |id, pl_name, pl_rade, sy_dist, pl_eqt, pl_orbper|
      point = { id: id, pl_name: pl_name, pl_rade: pl_rade, sy_dist: sy_dist, pl_eqt: pl_eqt }
      point[:pl_orbper] = pl_orbper if pl_orbper.present?
      point
    end
  end

  def system_counts
    counts = Exoplanet.where.not(hostname: [ nil, "" ]).group(:hostname).count
    counts = counts.select { |_, count| count >= MIN_MULTI_PLANET_COUNT } unless @include_single_planet

    counts.sort_by { |name, count| [ -count, name ] }
          .map { |name, count| { hostname: name, planet_count: count } }
  end

  # Distance is the same for every planet in a system, so any row's value
  # would do, but temperature varies planet-to-planet, so both are averaged
  # per system. Systems where no row has a usable value for either field are
  # dropped rather than plotted with a fabricated average.
  def systems_chart_points
    return [] if @systems.empty?

    hostnames = @systems.map { |system| system[:hostname] }
    values_by_host = Exoplanet.where(hostname: hostnames)
      .pluck(:hostname, :sy_dist, :pl_eqt)
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
    StellarHost.where(hostname: hostnames).pluck(:hostname, :st_spectype).each_with_object({}) do |(hostname, spectype), map|
      letter = spectype.to_s.strip[0]&.upcase
      map[hostname] = letter if SPECTRAL_CLASSES.include?(letter)
    end
  end
end
