namespace :datasets do
  desc "Import confirmed exoplanet data from NASA Exoplanet Archive"
  task import_exoplanets: :environment do
    ImportExoplanetsJob.perform_later
  end

  desc "Import stellar host data from NASA Exoplanet Archive"
  task import_stellar_hosts: :environment do
    ImportStellarHostsJob.perform_later
  end
end
