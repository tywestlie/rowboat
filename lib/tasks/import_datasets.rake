namespace :datasets do
  desc "Import confirmed exoplanet data from NASA Exoplanet Archive"
  task import_exoplanets: :environment do
    ImportExoplanetsJob.perform_now
  end
end
