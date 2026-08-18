class SystemsController < ApplicationController
  MIN_MULTI_PLANET_COUNT = 2
  SPECTRAL_CLASSES = %w[O B A F G K M].freeze

  def index
    @include_single_planet = params[:all] == "1"
    @systems = system_counts
    @systems_chart_points = systems_chart_points
  end

  def show
    @hostname = params[:hostname]
    @exoplanets = Exoplanet.where(hostname: @hostname).order(:id).page(params[:page]).per(50)
    @starfield_points = starfield_points
    @stellar_host = @exoplanets.first&.stellar_host
  end

  private

  def starfield_points
    Exoplanet.where(hostname: @hostname)
      .where.not(pl_rade: nil).where.not(sy_dist: nil).where.not(pl_eqt: nil).where.not(pl_orbper: nil)
      .pluck(:id, :pl_name, :pl_rade, :sy_dist, :pl_eqt, :pl_orbper)
      .map do |id, pl_name, pl_rade, sy_dist, pl_eqt, pl_orbper|
        { id: id, pl_name: pl_name, pl_rade: pl_rade, sy_dist: sy_dist, pl_eqt: pl_eqt, pl_orbper: pl_orbper }
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
